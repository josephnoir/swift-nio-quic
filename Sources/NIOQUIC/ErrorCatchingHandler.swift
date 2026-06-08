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

/// A channel handler that catches all errors, logs them and closes the channel.
final class ErrorCatchingHandler: ChannelInboundHandler {
    typealias InboundIn = Never

    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        self.logger.error(
            "ErrorCatchingHandler caught error",
            metadata: [
                LoggingKeys.error: "\(error)"
            ]
        )

        context.fireErrorCaught(error)
        context.close(promise: nil)
    }
}
