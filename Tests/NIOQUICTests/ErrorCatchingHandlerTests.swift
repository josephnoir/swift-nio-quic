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

import Logging
import NIOCore
import NIOEmbedded
import XCTest

@testable import NIOQUIC

final class ErrorCatchingHandlerTests: XCTestCase {
    private var channel: EmbeddedChannel!

    override func setUp() {
        super.setUp()

        self.channel = EmbeddedChannel()
    }

    override func tearDown() {
        super.tearDown()

        self.channel = nil
    }

    func testFireErrorCaught() throws {
        let handler = ErrorCatchingHandler(logger: Logger(label: "tests"))
        let mockHandler = MockChannelHandler()
        var context: ChannelHandlerContext?
        mockHandler.handlerAddedHandler = {
            context = $0
        }
        try self.channel.pipeline.syncOperations.addHandlers(mockHandler, handler)

        context?.fireErrorCaught(ChannelError.outputClosed)

        XCTAssertEqual(mockHandler.closeCallCount, 1)
    }
}
