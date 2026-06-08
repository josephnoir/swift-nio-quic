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

/// This protocol offers a customization point for different
/// writablity handling inside the child channels.
public protocol ChildChannelWritabilityStrategy {
    /// The type of messages of the child channel.
    associatedtype Message: FlowControlledMessage

    /// Returns if this is currently writable.
    var isWritable: Bool { get }

    /// Notifies the strategy that we have queued a message for writing to the network.
    ///
    /// - Parameter message: The message that was buffered in the child channel.
    mutating func bufferedMessage(_ message: Message)

    /// Notifies the strategy that we have successfully written a message to the network.
    ///
    /// - Parameter message: The message that was written to the parent channel.
    mutating func wroteMessage(_ message: Message)
}
