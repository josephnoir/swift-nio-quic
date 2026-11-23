//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import Logging
import NIOConcurrencyHelpers
import NIOCore
import NIOEmbedded
import NIOQUICHelpers
import XCTest

@testable import NIOQUIC

/// The client reads the server's CONNECTION_CLOSE in the same batch as stream frames the server sent
/// before it. The stack reports some of those stream frames only after the connection's close.
@available(anyAppleOS 27, *)
final class CloseInTheSameBatchTests: XCTestCase {
    /// The stack reports the reset after the connection's close when a stream the client doesn't know
    /// yet comes first in the batch.
    func testResetSentBeforeTheCloseIsReported() async throws {
        let pair = try await Pair.make()
        let uni = try await pair.openUniStreamOnServer()
        try await uni.writeAndFlush(ByteBuffer(string: "x"))
        try await pair.resetRequestStreamOnServer(code: 267)
        try await pair.closeConnectionOnServer()
        try await pair.deliverToClientInOneReadBatch(try await pair.serverDatagrams())

        let requestStreamErrors = pair.requestStreamErrors
        let errors = try await pair.loop.executeInContext {
            requestStreamErrors.thrownErrors.value.map { ($0 as? QUICStreamResetError)?.code }
        }
        // The reset comes first. The stream's close then adds the stack's own error, as for every
        // peer reset.
        XCTAssertEqual(errors.first, QUICApplicationErrorCode(267)!)
    }

    /// The stack reports data on a stream the client already knows after the connection's close.
    func testDataSentBeforeTheCloseIsDelivered() async throws {
        let pair = try await Pair.make()
        let uni = try await pair.openUniStreamOnServer()
        try await uni.writeAndFlush(ByteBuffer(string: "first;"))
        try await pair.pump()  // The client knows the stream now.
        try await uni.writeAndFlush(ByteBuffer(string: "second;"))
        try await pair.closeConnectionOnServer()
        try await pair.deliverToClientInOneReadBatch(try await pair.serverDatagrams())

        let read = try await pair.clientInboundStreamReads()
        XCTAssertEqual(read, ["first;second;"])
    }

    /// As the stream closes, the data the stack holds is delivered even though the stream never asked
    /// for a read.
    func testDataSentBeforeTheCloseIsDeliveredWithoutARead() async throws {
        let pair = try await Pair.make(autoReadInboundStreams: false)
        let uni = try await pair.openUniStreamOnServer()
        try await uni.writeAndFlush(ByteBuffer(string: "first;"))
        try await pair.pump()  // The client knows the stream now.
        try await uni.writeAndFlush(ByteBuffer(string: "second;"))
        try await pair.closeConnectionOnServer()
        try await pair.deliverToClientInOneReadBatch(try await pair.serverDatagrams())

        let read = try await pair.clientInboundStreamReads()
        XCTAssertEqual(read, ["first;second;"])
    }
}

/// An in-memory client and server. The client has opened stream 0 and sent a request with a FIN on it,
/// which the server has read. Datagrams only move when a test moves them.
@available(anyAppleOS 27, *)
private struct Pair {
    var loop: NIOAsyncTestingEventLoop
    var client: NIOAsyncTestingChannel
    var server: NIOAsyncTestingChannel
    var serverConnection: QUICConnection<Void>
    /// Stream 0 on the server.
    var serverRequestStream: any Channel
    /// The errors stream 0 caught on the client.
    var requestStreamErrors: ErrorCatchingHandler
    /// What the client read on each stream the server opened.
    var clientInboundStreams: NIOLockedValueBox<[ByteCollector]>

    static func make(autoReadInboundStreams: Bool = true) async throws -> Pair {
        let loop = NIOAsyncTestingEventLoop()
        let publicKeyPath = Bundle.module.url(forResource: "publicKey", withExtension: "der")!.path
        let privateKeyPath = Bundle.module.url(forResource: "privateKey", withExtension: "der")!.path

        let server = try await Self.makeChannel(loop: loop, localPort: 8080, remotePort: 9090)
        let client = try await Self.makeChannel(loop: loop, localPort: 9090, remotePort: 8080)
        let serverStreamPromise = loop.makePromise(of: (any Channel).self)
        let serverMultiplexer = try await loop.executeInContext {
            let (handler, multiplexer) = try QUICHandler.makeHandlerAndConnectionMultiplexer(
                channel: server,
                quicConfiguration: .forServer(
                    serverName: "quic-test.local",
                    authenticationConfiguration: .rawPublicKeys(
                        publicKeyFilePath: publicKeyPath,
                        privateKeyFilePath: privateKeyPath
                    ),
                    applicationProtocols: ["http/0.9"]
                ),
                logger: Logger(label: "Testing Server"),
                inboundStreamChannelInitializer: { channel in
                    serverStreamPromise.succeed(channel)
                    return channel.eventLoop.makeSucceededVoidFuture()
                }
            )
            try server.pipeline.syncOperations.addHandler(handler)
            server.pipeline.fireChannelActive()
            return multiplexer
        }
        let clientMultiplexer = try await loop.executeInContext {
            let (handler, multiplexer) = try QUICHandler.makeHandlerAndConnectionMultiplexer(
                channel: client,
                quicConfiguration: .forClient(
                    verificationConfiguration: .rawPublicKeys(publicKeyFilePath: publicKeyPath),
                    applicationProtocols: ["http/0.9"]
                ),
                logger: Logger(label: "Testing Client"),
                inboundStreamChannelInitializer: { $0.eventLoop.makeSucceededVoidFuture() }
            )
            try client.pipeline.syncOperations.addHandler(handler)
            client.pipeline.fireChannelActive()
            return multiplexer
        }

        let clientInboundStreams = NIOLockedValueBox<[ByteCollector]>([])
        let (clientConnection, serverConnection) = try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                while !Task.isCancelled {
                    try await Self.deliver(from: client, to: server)
                    try await Self.deliver(from: server, to: client)
                    await Task.yield()
                }
            }
            let clientConnection = try await clientMultiplexer.createNewConnection(
                serverName: "127.0.0.1",
                remoteAddress: server.localAddress!,
                inboundStreamInitializer: { channel in
                    let collector = ByteCollector(eventLoop: channel.eventLoop)
                    clientInboundStreams.withLockedValue { $0.append(collector) }
                    return channel.setOption(.autoRead, value: autoReadInboundStreams).flatMap {
                        channel.pipeline.addHandler(collector)
                    }
                }
            )
            var serverConnections = serverMultiplexer.inboundConnections.makeAsyncIterator()
            let serverConnection = await serverConnections.next()
            group.cancelAll()
            return (clientConnection, try XCTUnwrap(serverConnection))
        }

        let requestStreamErrors = ErrorCatchingHandler(eventLoop: loop)
        let requestStream = try await clientConnection.createBidirectionalStream { parameters in
            parameters.channel.pipeline.addHandler(requestStreamErrors).map { parameters.channel }
        }
        try await requestStream.writeAndFlush(ByteBuffer(string: "request"))
        try await requestStream.close(mode: .output)
        try await Self.pump(client, server)

        return Pair(
            loop: loop,
            client: client,
            server: server,
            serverConnection: serverConnection,
            serverRequestStream: try await serverStreamPromise.futureResult.get(),
            requestStreamErrors: requestStreamErrors,
            clientInboundStreams: clientInboundStreams
        )
    }

    /// Moves datagrams both ways until neither side has anything left to send.
    func pump() async throws {
        try await Self.pump(self.client, self.server)
    }

    func openUniStreamOnServer() async throws -> any Channel {
        try await self.serverConnection.createUnidirectionalStream {
            $0.channel.eventLoop.makeSucceededFuture($0.channel)
        }
    }

    func resetRequestStreamOnServer(code: UInt64) async throws {
        let stream = self.serverRequestStream
        try await self.loop.executeInContext {
            stream.triggerUserOutboundEvent(QUICResetStreamEvent(code: QUICApplicationErrorCode(code)!), promise: nil)
        }
    }

    func closeConnectionOnServer() async throws {
        let connection = self.serverRequestStream.parent!
        try await self.loop.executeInContext {
            connection.triggerUserOutboundEvent(
                QUICCloseConnectionEvent(code: QUICApplicationErrorCode(0x100)!, reasonPhrase: nil),
                promise: nil
            )
        }
    }

    /// Takes what the server wrote.
    func serverDatagrams() async throws -> [AddressedEnvelope<ByteBuffer>] {
        try await Self.datagrams(from: self.server)
    }

    /// Lets the client read all `datagrams` in one read batch, as from one `recvmmsg`.
    func deliverToClientInOneReadBatch(_ datagrams: [AddressedEnvelope<ByteBuffer>]) async throws {
        let client = self.client
        try await self.loop.executeInContext {
            for datagram in datagrams {
                client.pipeline.syncOperations.fireChannelRead(NIOAny(datagram))
            }
            client.pipeline.syncOperations.fireChannelReadComplete()
        }
        await self.loop.run()
    }

    /// What the client read on each stream the server opened.
    func clientInboundStreamReads() async throws -> [String] {
        let collectors = self.clientInboundStreams.withLockedValue { $0 }
        return try await self.loop.executeInContext { collectors.map { $0.bytes.value } }
    }

    private static func makeChannel(
        loop: NIOAsyncTestingEventLoop,
        localPort: Int,
        remotePort: Int
    ) async throws -> NIOAsyncTestingChannel {
        let channel = NIOAsyncTestingChannel(loop: loop)
        try await loop.executeInContext {
            channel.localAddress = try SocketAddress(ipAddress: "127.0.0.1", port: localPort)
            channel.remoteAddress = try SocketAddress(ipAddress: "127.0.0.1", port: remotePort)
        }
        try await channel.connect(to: channel.remoteAddress!)
        return channel
    }

    private static func pump(_ client: NIOAsyncTestingChannel, _ server: NIOAsyncTestingChannel) async throws {
        while true {
            let toServer = try await Self.deliver(from: client, to: server)
            let toClient = try await Self.deliver(from: server, to: client)
            if toServer + toClient == 0 {
                return
            }
        }
    }

    /// Takes everything `channel` wrote, split into datagrams as the kernel splits GSO writes. Runs the
    /// loop first: writes outside a read batch go out on the next loop tick.
    private static func datagrams(from channel: NIOAsyncTestingChannel) async throws -> [AddressedEnvelope<ByteBuffer>]
    {
        await channel.testingEventLoop.run()
        var datagrams: [AddressedEnvelope<ByteBuffer>] = []
        while var write = try await channel.readOutbound(as: AddressedEnvelope<ByteBuffer>.self) {
            if let segmentSize = write.metadata?.segmentSize, segmentSize > 0 {
                while write.data.readableBytes > 0 {
                    let datagram = write.data.readSlice(length: min(segmentSize, write.data.readableBytes))!
                    datagrams.append(AddressedEnvelope(remoteAddress: write.remoteAddress, data: datagram))
                }
            } else {
                datagrams.append(write)
            }
        }
        return datagrams
    }

    /// Moves datagrams from `source` to `destination` until `source` is quiet, each in a read batch of
    /// its own, and returns how many it moved.
    @discardableResult
    private static func deliver(
        from source: NIOAsyncTestingChannel,
        to destination: NIOAsyncTestingChannel
    ) async throws -> Int {
        var delivered = 0
        while true {
            let datagrams = try await Self.datagrams(from: source)
            if datagrams.isEmpty {
                return delivered
            }
            for datagram in datagrams {
                try await destination.writeInbound(datagram)
            }
            delivered += datagrams.count
        }
    }
}

/// Collects what's read on a stream.
@available(anyAppleOS 27, *)
private final class ByteCollector: ChannelInboundHandler, Sendable {
    typealias InboundIn = ByteBuffer

    let bytes: NIOLoopBoundBox<String>

    init(eventLoop: any EventLoop) {
        self.bytes = .makeBoxSendingValue("", eventLoop: eventLoop)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        self.bytes.value += String(buffer: Self.unwrapInboundIn(data))
    }
}
