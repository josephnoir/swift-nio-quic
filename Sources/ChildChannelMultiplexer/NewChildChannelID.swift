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

/// A type used initialise a new child channel.
public enum NewChildChannelID<ChildChannelID, ChildChannelIDProperties> {
    /// Indicates that there is already an ID for the new child channel.
    case channelID(ChildChannelID)
    /// Indicates that an ID should be created on the first write of the new child channel.
    case pending(ChildChannelIDProperties)

    @inlinable
    var childChannelID: ChildChannelID? {
        switch self {
        case .channelID(let childChannelID):
            return childChannelID

        case .pending:
            return nil
        }
    }
}

extension NewChildChannelID: Sendable where ChildChannelID: Sendable, ChildChannelIDProperties: Sendable {}
