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

final class MockChannelHandler: ChannelDuplexHandler {
    public typealias InboundIn = Any
    public typealias InboundOut = Any
    public typealias OutboundIn = Any
    public typealias OutboundOut = Any

    var userInboundEventTriggeredCallCount = 0
    var userInboundEventTriggeredHandler: ((ChannelHandlerContext, Any) -> Void)?
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        self.userInboundEventTriggeredCallCount += 1
        if let userInboundEventTriggeredHandler = self.userInboundEventTriggeredHandler {
            userInboundEventTriggeredHandler(context, event)
            return
        }
        return
    }

    var handlerAddedCallCount = 0
    var handlerAddedHandler: ((ChannelHandlerContext) -> Void)?
    func handlerAdded(context: ChannelHandlerContext) {
        self.handlerAddedCallCount += 1
        if let handlerAddedHandler = self.handlerAddedHandler {
            handlerAddedHandler(context)
            return
        }
        return
    }

    var closeCallCount = 0
    var closeHandler: ((ChannelHandlerContext, CloseMode, EventLoopPromise<Void>?) -> Void)?
    func close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
        self.closeCallCount += 1
        if let closeHandler = self.closeHandler {
            closeHandler(context, mode, promise)
            return
        }
        return
    }
}
