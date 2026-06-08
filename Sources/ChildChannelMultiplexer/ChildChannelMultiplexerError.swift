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

/// An error thrown by ChildChannelMultiplexer.
public struct ChildChannelMultiplexerError: Error, Hashable {
    internal enum InternalError: Hashable {
        case multiplexerShutdown
        case parentChannelShutdown
        case unknownChannelID
        case cannotRemoveLastChannelID
    }

    internal var internalError: InternalError

    /// Indicates that the mutliplexer already shutdown.
    public static let multiplexerShutdown = Self(internalError: .multiplexerShutdown)

    /// Indicates that the parent channel has been shutdown.
    public static let parentChannelShutdown = Self(internalError: .parentChannelShutdown)

    /// Indicates that no channel with the given channel ID exists.
    public static let unknownChannelID = Self(internalError: .unknownChannelID)

    /// Indicates that a channel ID cannot be removed.
    public static let cannotRemoveLastChannelID = Self(internalError: .cannotRemoveLastChannelID)
}
