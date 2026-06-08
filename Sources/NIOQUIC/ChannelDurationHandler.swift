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

import Dispatch
import Metrics
import NIOCore

/// A channel handler that measures the duration of the channel (i.e. from channel active to channel inactive).
final class ChannelDurationHandler: ChannelInboundHandler {
    typealias InboundIn = QUICConnectionChannelInboundMessage
    typealias OutboundOut = QUICConnectionChannelOutboundMessage

    private let durationTimer: Timer
    private var startTime: DispatchTime?

    init(durationTimer: Timer) {
        self.durationTimer = durationTimer
    }

    func channelActive(context: ChannelHandlerContext) {
        self.startTime = .now()
        context.fireChannelActive()
    }

    func channelInactive(context: ChannelHandlerContext) {
        if let startTime = self.startTime {
            self.durationTimer.recordInterval(since: startTime)
        }
        context.fireChannelInactive()
    }
}
