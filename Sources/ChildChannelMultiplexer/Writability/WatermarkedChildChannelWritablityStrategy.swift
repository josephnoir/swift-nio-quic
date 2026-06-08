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

/// Keeps track of whether or not a ``ChildChannel`` should be able to write based on watermarks.
///
/// A ``WatermarkedWritablityStrategy`` is a straightforward object that keeps track of
/// the number of to-be-written bytes in a ``ChildChannel``, as well as the trajectory of those
/// bytes. This allows a ``ChildChannel`` to buffer a certain number of bytes before flipping its
/// writability state, and then allows draining to a different watermark before the state flips
/// again.
///
/// The goal here is to constrain the number of resources allocated for a task, while also ensuring
/// that ``ChildChannel`` writability state doesn't flick between writable and not-writable rapidly. This produces
/// a more stable system that responds better to changes in the underlying network.
///
/// The strategy keeps track of the number of pending bytes (that is, bytes that have been written but not yet
/// reached the network), as well as a high and a low watermark. If the number of pending bytes exceeds the high
/// watermark, the writability state changes to false. If the number of pending bytes is below the low watermark,
/// the writability state changes to true.
///
/// If the number of pending bytes is between the two watermarks, the writability state remains in whatever the previous
/// state was. This essentially causes a "lag" in the change of writability state: once the state flips, it will take a while
/// for the number of pending bytes to cross the other threshold to cause the state to flip again.
public struct WatermarkedChildChannelWritablityStrategy<Message: FlowControlledMessage>:
    ChildChannelWritabilityStrategy, Sendable
{
    /// The "high" water mark. If the number of pending bytes exceeds this number, the
    /// writability state will change to `false`.
    @usableFromInline
    let _highWatermark: UInt

    /// The "low" watermark. If the number of pending bytes is lower than this number, the
    /// writability state will change to `true`.
    @usableFromInline
    let _lowWatermark: UInt

    /// The number of pending bytes waiting to be written to the network.
    @usableFromInline
    var _pendingBytes: UInt

    /// Whether the ``ChildChannel`` should consider itself writable or not.
    @inlinable
    public var isWritable: Bool {
        self._isWritable
    }

    /// Private `isWritable` storage.
    @usableFromInline
    var _isWritable: Bool

    public init(highWatermark: Int, lowWatermark: Int) {
        precondition(
            lowWatermark < highWatermark,
            "Low watermark \(lowWatermark) exceeds or meets high watermark \(highWatermark)"
        )

        self._highWatermark = UInt(highWatermark)
        self._lowWatermark = UInt(lowWatermark)
        self._pendingBytes = 0
        self._isWritable = true
    }

    @inlinable
    public mutating func bufferedMessage(_ message: Message) {
        self._pendingBytes += UInt(message.flowControlSize)
        if self._pendingBytes > self._highWatermark {
            self._isWritable = false
        }
    }

    @inlinable
    public mutating func wroteMessage(_ message: Message) {
        self._pendingBytes -= UInt(message.flowControlSize)
        if self._pendingBytes < self._lowWatermark {
            self._isWritable = true
        }
    }
}
