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

/// A struct that represents an action that the ``ChildChannel`` should execute.
public struct ChildChannelAction<
    ParentInboundMessage,
    ParentOutboundMessage,
    ChildInboundMessage,
    ChildOutboundMessage,
    Task
> {
    /// The internal action to avoid exposing an enum publicly.
    @usableFromInline
    internal enum Action: CustomDebugStringConvertible {
        // Public actions
        case childChannelCompleteActivation
        case childChannelBufferRead(ChildInboundMessage)
        case childChannelFireChannelRead(ChildInboundMessage)
        case childChannelBufferInputClosed
        case childChannelFireInputClosed
        case childChannelCloseCleanly(EventLoopPromise<Void>?)
        case childChannelFailClose(Error, EventLoopPromise<Void>?)
        case childChannelEncounterError(Error, EventLoopPromise<Void>?)
        case childChannelFireUserInboundEventTriggered(Any)
        case childChannelFlush
        case succeedPromise(EventLoopPromise<Void>)
        case failPromise(EventLoopPromise<Void>, Error)
        case childChannelScheduleTask(Task, NIODeadline)
        case childChannelCancelTask(Task)
        case parentChannelWrite(ParentOutboundMessage, EventLoopPromise<Void>?)
        case parentChannelRead

        // Internal actions
        case deliverPendingWritesToStateMachine
        case writePendingToMultiplexer
        case deliverPendingReads
        case fireChannelReadComplete
        case fireErrorCaught(Error)
        case failPendingWrites(Error)
        case failChannelPromise(EventLoopPromise<Channel>, Error)
        case notifyChannelInactive

        @usableFromInline
        var debugDescription: String {
            switch self {
            // Public actions
            case .childChannelCompleteActivation:
                return "childChannelCompleteActivation"
            case .childChannelBufferRead:
                return "childChannelBufferRead"
            case .childChannelFireChannelRead:
                return "childChannelFireChannelRead"
            case .childChannelBufferInputClosed:
                return "childChannelBufferInputClosed"
            case .childChannelFireInputClosed:
                return "childChannelFireInputClosed"
            case .childChannelCloseCleanly:
                return "childChannelCloseCleanly"
            case .childChannelFailClose:
                return "childChannelFailClose"
            case .childChannelEncounterError:
                return "childChannelEncounterError"
            case .childChannelFireUserInboundEventTriggered:
                return "childChannelFireUserInboundEventTriggered"
            case .childChannelFlush:
                return "childChannelFlush"
            case .succeedPromise:
                return "succeedPromise"
            case .failPromise:
                return "failPromise"
            case .childChannelScheduleTask(let task, let deadline):
                return "childChannelScheduleTask(\(task), \(deadline))"
            case .childChannelCancelTask(let task):
                return "childChannelCancelTask(\(task))"
            case .parentChannelWrite:
                return "parentChannelWrite"
            case .parentChannelRead:
                return "parentChannelRead"

            // Internal actions
            case .deliverPendingWritesToStateMachine:
                return "deliverPendingWritesToStateMachine"
            case .writePendingToMultiplexer:
                return "writePendingToMultiplexer"
            case .deliverPendingReads:
                return "deliverPendingReads"
            case .fireChannelReadComplete:
                return "fireChannelReadComplete"
            case .fireErrorCaught:
                return "fireErrorCaught"
            case .failPendingWrites:
                return "failPendingWrites"
            case .failChannelPromise:
                return "failChannelPromise"
            case .notifyChannelInactive:
                return "notifyChannelInactive"
            }
        }
    }

    /// The actual action.
    @usableFromInline
    internal var action: Action

    /// The ID of any actions which depend on this action.
    @usableFromInline
    internal var dependentActionID: Optional<UInt64>

    @inlinable
    init(action: Action, dependentActionID: UInt64? = nil) {
        self.action = action
        self.dependentActionID = dependentActionID
    }

    // MARK: - Public actions

    /// Tells the child channel to complete the activation.
    @inlinable
    public static var childChannelCompleteActivation: Self {
        Self(action: .childChannelCompleteActivation)
    }

    /// Tells the child channel to buffer a message to be read.
    ///
    /// - Parameter message: The message to buffer.
    @inlinable
    public static func childChannelBufferRead(message: ChildInboundMessage) -> Self {
        Self(action: .childChannelBufferRead(message))
    }

    /// Tells the child channel to fire a ``channelRead`` down the channel pipeline.
    ///
    /// - Parameter message: The message that was read and is ready to process.
    @inlinable
    public static func childChannelFireChannelRead(message: ChildInboundMessage) -> Self {
        Self(action: .childChannelFireChannelRead(message))
    }

    /// Tells the child channel to buffer an inputClosed event. This will be buffered behind any currently buffered reads.
    ///
    /// - Note: This is equivalent to ``ChildChannelAction/childChannelFireUserInboundEventTriggered(event:)`` with event `ChannelEvent.inputClosed`.
    @inlinable
    public static var childChannelBufferInputClosed: Self {
        Self(action: .childChannelBufferInputClosed)
    }

    /// Tells the child channel to actually fire an `inputClosed` down the channel pipeline. This will overtake any buffered reads.
    ///
    @inlinable
    public static var childChannelFireInputClosed: Self {
        Self(action: .childChannelFireInputClosed)
    }

    /// Tells the child channel to schedule a task.
    ///
    /// Once the task is executed on the child channel, the state machine will get
    /// a ``childChannelExecuteTask`` call with the passed  task.
    ///
    /// - Parameters:
    ///   - task: The task to schedule.
    ///   - deadline: Deadline when the task will be executed.
    @inlinable
    public static func childChannelScheduleTask(_ task: Task, deadline: NIODeadline) -> Self {
        Self(action: .childChannelScheduleTask(task, deadline))
    }

    /// Tells the child channel to cancel a task.
    ///
    /// - Parameter task: The task to cancel.
    @inlinable
    public static func childChannelCancelTask(_ task: Task) -> Self {
        Self(action: .childChannelCancelTask(task))
    }

    /// Tells the child channel to write a message to the parent channel.
    ///
    /// - Parameters:
    ///   - message: The message to write to the parent channel.
    ///   - promise: The ``EventLoopPromise`` which should be notified once the write completes, or nil if no notification should take place.
    @inlinable
    public static func parentChannelWrite(message: ParentOutboundMessage, promise: EventLoopPromise<Void>?) -> Self {
        Self(action: .parentChannelWrite(message, promise))
    }

    /// Tells the child channel to issue a read to the parent channel.
    @inlinable
    public static var parentChannelRead: Self {
        Self(action: .parentChannelRead)
    }

    /// Tells the child channel to close cleanly.
    ///
    /// - Parameters:
    ///   - promise: The ``EventLoopPromise`` which will be succeeded once the channel is closed.
    @inlinable
    public static func childChannelCloseCleanly(promise: EventLoopPromise<Void>?) -> Self {
        Self(action: .childChannelCloseCleanly(promise))
    }

    /// Tells the child channel to fail closing.
    ///
    /// - Parameters:
    ///   - error: The error why the close failed.
    ///   - promise: The ``EventLoopPromise`` which will be succeeded once the channel is closed.
    @inlinable
    public static func childChannelFailClose(error: Error, promise: EventLoopPromise<Void>?) -> Self {
        Self(action: .childChannelFailClose(error, promise))
    }

    /// Tells the child channel that it encountered an error. This results in the channel
    /// being closed.
    ///
    /// - Parameters:
    ///   - error: The error that was encountered.
    ///   - promise: The ``EventLoopPromise`` which will be succeeded once the channel is closed.
    @inlinable
    public static func childChannelEncounterError(error: Error, promise: EventLoopPromise<Void>?) -> Self {
        Self(action: .childChannelEncounterError(error, promise))
    }

    /// Trigger a custom user inbound event which will flow through the child channel pipeline.
    ///
    /// - Parameter event: The event to fire.
    /// - Note: If the event is a `ChannelEvent.inputClosed`, it will be buffered behind any buffered reads, and is equivalent to using the ``ChildChannelAction/childChannelBufferInputClosed`` action.
    @inlinable
    public static func childChannelFireUserInboundEventTriggered(event: Any) -> Self {
        Self(action: .childChannelFireUserInboundEventTriggered(event))
    }

    /// Tells the child channel to flush all previously written data.
    @inlinable
    public static var childChannelFlush: Self {
        Self(action: .childChannelFlush)
    }

    /// Fails the provided promise.
    ///
    /// - Parameters:
    ///  - promise: The promise to fail.
    ///  - error: The error to fail the promise with.
    @inlinable
    public static func failPromise(_ promise: EventLoopPromise<Void>, withError error: Error) -> Self {
        Self(action: .failPromise(promise, error))
    }

    /// Succeeds the provided promise.
    @inlinable
    public static func succeedPromise(_ promise: EventLoopPromise<Void>) -> Self {
        Self(action: .succeedPromise(promise))
    }

    // MARK: - Internal actions

    /// Tells the child channel to write all pending writes to the multiplexer.
    @inlinable
    static var writePendingToMultiplexer: Self {
        Self(action: .writePendingToMultiplexer)
    }

    /// Tells the child channel to fire a `ReadComplete` down the pipeline .
    @inlinable
    static var fireChannelReadComplete: Self {
        Self(action: .fireChannelReadComplete)
    }

    /// Tells the child channel to fire a `ErrorCaught` down the pipeline.
    ///
    /// - Parameter error: The error to fire.
    @inlinable
    static func fireErrorCaught(_ error: Error) -> Self {
        Self(action: .fireErrorCaught(error))
    }

    /// Tells the child channel to fail all pending writes .
    ///
    /// - Parameter error: The error to fire.
    @inlinable
    static func failPendingWrites(_ error: Error) -> Self {
        Self(action: .failPendingWrites(error))
    }

    /// Fails the provided promise.
    ///
    /// - Parameters:
    ///  - promise: The promise to fail.
    ///  - error: The error to fail the promise with.
    @inlinable
    static func failChannelPromise(_ promise: EventLoopPromise<Channel>, withError error: Error) -> Self {
        Self(action: .failChannelPromise(promise, error))
    }

    /// Tells the child channel to notify the pipeline that the channel is inactive.
    @inlinable
    static var notifyChannelInactive: Self {
        Self(action: .notifyChannelInactive)
    }
}

@available(*, unavailable)
extension ChildChannelAction: Sendable {}

@available(*, unavailable)
extension ChildChannelAction.Action: Sendable {}
