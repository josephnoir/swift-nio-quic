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

import NIOCore

/// This is a manual existential wrapper around a `Channel` and `ChannelCore`.
/// We need this so that the calls to the `ChildChannel` methods from the channel pipeline
/// get specialized properly.
/// - Note: it's okay to mark this type as `@unchecked Sendable` because the non-`Sendable`
/// properties it stores are functions that are part of the `ChannelCore` protocol, which is isolated to
/// the EventLoop and is thus concurrency-safe.
@usableFromInline
final class AnyChannel: Channel, ChannelCore, @unchecked Sendable {
    @usableFromInline
    var allocator: NIOCore.ByteBufferAllocator {
        self.channel.allocator
    }

    @usableFromInline
    var closeFuture: NIOCore.EventLoopFuture<Void> {
        self.channel.closeFuture
    }

    @usableFromInline
    var pipeline: NIOCore.ChannelPipeline {
        self.channel.pipeline
    }

    @usableFromInline
    var localAddress: NIOCore.SocketAddress? {
        self.channel.localAddress
    }

    @usableFromInline
    var remoteAddress: NIOCore.SocketAddress? {
        self.channel.remoteAddress
    }

    @usableFromInline
    var parent: NIOCore.Channel? {
        self.channel.parent
    }

    @usableFromInline
    var isWritable: Bool {
        self.channel.isWritable
    }

    @usableFromInline
    var isActive: Bool {
        self.channel.isActive
    }

    @usableFromInline
    var _channelCore: NIOCore.ChannelCore {
        // It is important that we return self here so that the calls get specialized.
        self
    }

    @usableFromInline
    var eventLoop: NIOCore.EventLoop {
        self.channel.eventLoop
    }

    @usableFromInline
    let channel: any Channel

    @usableFromInline
    let _write0: (NIOAny, EventLoopPromise<Void>?) -> Void

    @usableFromInline
    let _flush0: () -> Void

    @usableFromInline
    let _read0: () -> Void

    @usableFromInline
    let _close0: (Error, CloseMode, EventLoopPromise<Void>?) -> Void

    @usableFromInline
    let _triggerUserOutboundEvent0: (Any, EventLoopPromise<Void>?) -> Void

    @usableFromInline
    let _channelRead0: (NIOAny) -> Void

    @usableFromInline
    let _errorCaught0: (Error) -> Void

    @inlinable
    init(channel: some Channel & ChannelCore) {
        self.channel = channel
        self._write0 = channel.write0(_:promise:)
        self._flush0 = channel.flush0
        self._read0 = channel.read0
        self._close0 = channel.close0(error:mode:promise:)
        self._triggerUserOutboundEvent0 = channel.triggerUserOutboundEvent0(_:promise:)
        self._channelRead0 = channel.channelRead0(_:)
        self._errorCaught0 = channel.errorCaught0(error:)
    }

    @inlinable
    func setOption<Option>(_ option: Option, value: Option.Value) -> EventLoopFuture<Void> where Option: ChannelOption {
        self.channel.setOption(option, value: value)
    }

    @inlinable
    func getOption<Option>(_ option: Option) -> EventLoopFuture<Option.Value> where Option: ChannelOption {
        self.channel.getOption(option)
    }

    @inlinable
    func localAddress0() throws -> NIOCore.SocketAddress {
        try self.channel._channelCore.localAddress0()
    }

    @inlinable
    func remoteAddress0() throws -> NIOCore.SocketAddress {
        try self.channel._channelCore.remoteAddress0()
    }

    @inlinable
    func register0(promise: NIOCore.EventLoopPromise<Void>?) {
        self.channel._channelCore.register0(promise: promise)
    }

    @inlinable
    func bind0(to: NIOCore.SocketAddress, promise: NIOCore.EventLoopPromise<Void>?) {
        self.channel._channelCore.bind0(to: to, promise: promise)
    }

    @inlinable
    func connect0(to: NIOCore.SocketAddress, promise: NIOCore.EventLoopPromise<Void>?) {
        self.channel._channelCore.connect0(to: to, promise: promise)
    }

    @inlinable
    func write0(_ data: NIOCore.NIOAny, promise: NIOCore.EventLoopPromise<Void>?) {
        self._write0(data, promise)
    }

    @inlinable
    func flush0() {
        self._flush0()
    }

    @inlinable
    func read0() {
        self._read0()
    }

    @inlinable
    func close0(error: Error, mode: NIOCore.CloseMode, promise: NIOCore.EventLoopPromise<Void>?) {
        self._close0(error, mode, promise)
    }

    @inlinable
    func triggerUserOutboundEvent0(_ event: Any, promise: NIOCore.EventLoopPromise<Void>?) {
        self._triggerUserOutboundEvent0(event, promise)
    }

    @inlinable
    func channelRead0(_ data: NIOCore.NIOAny) {
        self._channelRead0(data)
    }

    @inlinable
    func errorCaught0(error: Error) {
        self._errorCaught0(error)
    }
}
