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

/// Tracks queue depths across the outbound data path.
/// All properties are updated on the event loop — no synchronization needed.
struct QUICOutboundFlowTracker {
    /// Q4: Connection state machine pending stream writes
    var pendingStreamWriteCount: Int = 0
    var pendingStreamWriteBytes: Int = 0
    /// Q5: Finalized output packets waiting to be written to NIO
    var finalizedOutputCount: Int = 0
    var finalizedOutputBytes: Int = 0
    /// Total packets drained from Q5 since connection start
    var totalPacketsDrained: Int = 0
    /// Total bytes drained from Q5 since connection start
    var totalBytesDrained: Int = 0
    /// Number of short writes (partial writes in deliverPendingStreamWrites)
    var shortWriteCount: Int = 0
}
