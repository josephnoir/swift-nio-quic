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

/// The outbound flow control manager for ``ChildChannel`` objects.
///
/// Our flow control strategy here is in two parts. The first is a custom strategy that
/// can be supplied by the user of the multiplexer.
///
/// The second is a parent-channel based observation. If the parent channel is not writable,
/// there is no reason to tell the stream channels that they can write either, as those writes
/// will simply back up in the parent.
///
/// The observed effect is that the ``ChildChannel`` is writable only if both of the above
/// strategies are writable: if either is not writable, neither is the ``ChildChannel``.
@usableFromInline
struct ChildChannelWritabilityManager<
    Strategy: ChildChannelWritabilityStrategy,
    Message
> where Strategy.Message == Message {
    /// The strategy.
    @usableFromInline
    var _strategy: Strategy
    /// Indicates wether the parent is currently writable.
    @usableFromInline
    var _parentIsWritable: Bool
    /// The logger.
    @usableFromInline
    let logger: Logger

    @inlinable
    init(
        strategy: Strategy,
        parentIsWritable: Bool,
        logger: Logger
    ) {
        self._strategy = strategy
        self._parentIsWritable = parentIsWritable
        self.logger = logger
    }
}

@available(*, unavailable)
extension ChildChannelWritabilityManager: Sendable {}

extension ChildChannelWritabilityManager {
    /// Indicates whether the ``ChildChannel`` is writable.
    @usableFromInline
    var isWritable: Bool {
        self._strategy.isWritable && self._parentIsWritable
    }
}

extension ChildChannelWritabilityManager {
    /// A value representing a change in writability.
    @usableFromInline
    enum WritabilityChange: Hashable, Sendable {
        /// No writability change occurred
        case noChange

        /// Writability changed to a new value.
        case changed(newValue: Bool)
    }
}

extension ChildChannelWritabilityManager {
    /// Notifies the  ``ChildChannelWritabilityManager`` that we have queued a message for writing to the network.
    ///
    /// - Parameter message: The message that was buffered.
    /// - Returns: If a change of writability happened.
    @inlinable
    mutating func bufferedMessage(_ message: Message) -> WritabilityChange {
        self.logger.trace(
            "ChildChannelWritabilityManager buffered message",
            metadata: [
                LoggingKeys.childChannelWritabilityManagerFlowControlSize: "\(message.flowControlSize)"
            ]
        )
        return self._mayChangeWritability {
            $0._strategy.bufferedMessage(message)
        }
    }

    /// Notifies the ``ChildChannelWritabilityManager`` that we have successfully written a message to the network.
    ///
    /// - Parameter message: The message that was written.
    /// - Returns: If a change of writability happened.
    @inlinable
    mutating func wroteMessage(_ message: Message) -> WritabilityChange {
        self.logger.trace(
            "ChildChannelWritabilityManager wrote message",
            metadata: [
                LoggingKeys.childChannelWritabilityManagerFlowControlSize: "\(message.flowControlSize)"
            ]
        )
        return self._mayChangeWritability {
            $0._strategy.wroteMessage(message)
        }
    }

    /// Notifies the ``ChildChannelWritabilityManager`` that the writability of the parent changed.
    ///
    /// - Parameter newWritability: The new writability state of the parent.
    /// - Returns: If a change of writability happened.
    @inlinable
    mutating func parentWritabilityChanged(_ newWritability: Bool) -> WritabilityChange {
        self._mayChangeWritability {
            $0._parentIsWritable = newWritability
        }
    }

    @inlinable
    mutating func _mayChangeWritability(_ body: (inout ChildChannelWritabilityManager) -> Void) -> WritabilityChange {
        let wasWritable = self.isWritable
        body(&self)
        let isWritable = self.isWritable

        guard wasWritable != isWritable else {
            return .noChange
        }
        return .changed(newValue: isWritable)
    }
}
