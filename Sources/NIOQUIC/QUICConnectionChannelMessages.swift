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

import ChildChannelMultiplexer
import NIOCore
import NIOQUICHelpers

/// The connection channel's inbound message.
struct QUICConnectionChannelInboundMessage: Hashable {
    /// The readable's stream id.
    var streamID: QUICStreamID
}

/// The connection channel's outbound message.
struct QUICConnectionChannelOutboundMessage: Hashable {
    /// The stream ID of the data.
    var streamID: QUICStreamID
    /// The message to send.
    var streamMessage: QUICStreamMessage
}

extension QUICConnectionChannelOutboundMessage: FlowControlledMessage {
    var flowControlSize: Int {
        self.streamMessage.data.readableBytes
    }
}

/// An event indicating that a STOP_SENDING frame was received from the peer,
/// routed through the multiplexer so delivery is synchronized with buffered reads.
struct QUICStreamStopSendingReceivedEvent {
    /// The id of the stream channel.
    var streamID: QUICStreamID
    /// The application error code from the STOP_SENDING frame.
    var applicationErrorCode: QUICApplicationErrorCode
}

/// An event indicating that a RESET_STREAM frame was received from the peer,
/// routed through the multiplexer so delivery is synchronized with buffered reads.
struct QUICStreamResetStreamReceivedEvent {
    /// The id of the stream channel.
    var streamID: QUICStreamID
    /// The application error code from the RESET_STREAM frame.
    var applicationErrorCode: QUICApplicationErrorCode
}
