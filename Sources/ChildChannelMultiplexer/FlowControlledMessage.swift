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

/// A protocol for messages that are written and read on a ``ChildChannel``.
public protocol FlowControlledMessage {
    /// The size of the message in bytes.
    ///
    /// This is used to properly calculate the flow control impact of
    /// a single message.
    ///
    /// - Important: This must not be negative. Furthermore, this must be implemented by the
    /// parent and child channel message. In the end, the aggregate of the buffered message sizes needs to be
    /// the same as the aggregate of the written message sizes.
    var flowControlSize: Int { get }
}

extension ByteBuffer: FlowControlledMessage {
    public var flowControlSize: Int {
        self.readableBytes
    }
}

extension AddressedEnvelope<ByteBuffer>: FlowControlledMessage {
    public var flowControlSize: Int {
        self.data.readableBytes
    }
}
