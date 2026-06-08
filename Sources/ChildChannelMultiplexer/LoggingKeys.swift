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

@usableFromInline
enum LoggingKeys: Sendable {
    @usableFromInline
    static let parentChannelWritability = "parentChannel.writability"
    @usableFromInline
    static let parentChannelUserInboundEvent = "parentChannel.userInboundEvent"
    @usableFromInline
    static let childChannelID = "childChannel.id"
    @usableFromInline
    static let childChannelWritability = "childChannel.writability"
    @usableFromInline
    static let childChannelActionsCount = "childChannel.actionsCount"
    @usableFromInline
    static let childChannelActions = "childChannel.actions"
    @usableFromInline
    static let childChannelUserInboundEvent = "childChannel.userInboundEvent"
    @usableFromInline
    static let childChannelUserOutboundEvent = "childChannel.userOutboundEvent"
    @usableFromInline
    static let childChannelTask = "childChannel.task"
    @usableFromInline
    static let childChannelTaskDeadline = "childChannel.taskDeadline"
    @usableFromInline
    static let childChannelWritabilityManagerFlowControlSize = "childChannelWritabilityManager.flowControlSize"
    @usableFromInline
    static let error = "error"
}
