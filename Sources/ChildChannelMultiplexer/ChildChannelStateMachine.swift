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

/// A state machine for the child channel.
///
/// The state machine acts as a customization point for users of the multiplexer.
/// Every important event that happens inside the child channel or from the parent channel is forwarded to the state machine.
/// A concrete implementation can then return a collection of actions that should be performed by the child channel.
public protocol ChildChannelStateMachine {
    /// The type of the child channel ID.
    associatedtype ChildChannelID
    /// The type of the ID properties of the child channels.
    associatedtype ChildChannelIDProperties
    /// The type of the inbound messages of the parent channel.
    associatedtype ParentChannelInboundMessage
    /// The type of the outbound messages of the parent channel.
    associatedtype ParentChannelOutboundMessage
    /// The type of the inbound messages of the child channel.
    associatedtype ChildChannelInboundMessage
    /// The type of the outbound messages of the child channel.
    associatedtype ChildChannelOutboundMessage
    /// The type of the tasks of this state machine. These tasks must be ``Hashable`` to properly schedule and cancel them.
    associatedtype Task: Hashable = Never

    typealias Actions = ChildChannelActions<
        ParentChannelInboundMessage, ParentChannelOutboundMessage, ChildChannelInboundMessage,
        ChildChannelOutboundMessage, Task
    >

    // MARK: - Child channel events

    /// Called after the initialization succeeded.
    ///
    /// This should return a ``ChildChannelAction.childChannelCompleteActivation`` if the state machine is
    /// ready to send/receive messages. If the state machine cannot return ``ChildChannelAction.childChannelCompleteActivation``
    /// from here because of i.e. protocol requirements, it needs to make sure to activate the channel later.
    mutating func childChannelInitializationSucceeded() -> Actions

    /// Called after the initialization failed.
    mutating func childChannelInitializationFailed(error: Error) -> Actions

    /// Called when ``getChannelOption`` is called on the child channel.
    ///
    /// - Parameters:
    ///     - option: The option to get the value for.
    /// - Returns: The value of the option.
    mutating func childChannelGetOption<Option: ChannelOption>(_ option: Option) throws -> Option.Value

    /// Called when ``setChannelOption`` is called on the child channel.
    ///
    /// - Parameters:
    ///     - option: The option to set the value for.
    ///     - value: The value to set the option to.
    mutating func childChannelSetOption<Option: ChannelOption>(_ option: Option, value: Option.Value) throws

    /// Called when the child channel ID is generated.
    ///
    /// This happens if the child channel was created with a `pending` ID.
    mutating func childChannelIDGenerated(childChannelID: ChildChannelID) -> Actions

    /// Called from ``write0`` before a write is buffered.
    ///
    /// The state machine should check if it is in a valid state to
    /// write. If it isn't it should throw an error.
    ///
    /// - Throws: The error why it cannot write.
    mutating func childChannelCanWrite() throws

    /// Called when the child channel is flushed.
    /// This method is called for every individual method that is buffered for the
    /// parent channel.
    ///
    /// In the regular case this should return a ``ChildChannelAction.parentChannelWrite`` so that the message
    /// is written to the parent channel.
    ///
    /// - Parameters:
    ///   - message: The message to write to the parent channel.
    ///   - promise: The ``EventLoopPromise`` which should be notified once the write completes, or nil if no notification should take place.
    mutating func childChannelWriteMessage(
        _ message: ChildChannelOutboundMessage,
        promise: EventLoopPromise<Void>?
    ) -> Actions

    /// Called before the child channel tries to read the buffered messages.
    ///
    /// - Returns: A boolean indicating wether the state machine is in a state to read.
    mutating func childChannelCanRead() -> Bool

    /// Called when the child channel wants to read new data from the parent channel.
    ///
    /// In the regular case, this should return a ``ChildChannelAction.parentChannelRead`` so that the read
    /// is forwarded to parent channel.
    mutating func childChannelReadFromParent() -> Actions

    /// Called when the child channel read a message.
    ///
    /// In the regular case this should return a ``ChildChannelAction.childChannelFireChannelRead`` to send the
    /// message down the channel pipeline.
    ///
    /// - Parameter message: The message that was read by the child channel.
    mutating func childChannelReadMessage(_ message: ChildChannelInboundMessage) -> Actions

    /// Called when the child channel received an inputClosed event.
    ///
    /// In the regular case this should return a ``ChildChannelAction/childChannelFireInputClosed`` to send the
    /// EOF down the channel pipeline.
    ///
    mutating func childChannelReceivedInputClosed() -> Actions

    /// Called before the child channel changes its writability state.
    ///
    /// This is useful to prevent writability changes before the channel became active.
    ///
    /// - Returns: A boolean indicating wether the channel should change its writability.
    mutating func childChannelShouldChangeWritability() -> Bool

    /// Called when the channel received an outbound user event.
    ///
    /// - Parameters:
    ///   - event: The outbound user event.
    ///   - promise: The ``EventLoopPromise`` which should be notified once the operation completes, or nil if no notification should take place.
    mutating func childChannelTriggerUserOutboundEvent(_ event: Any, promise: EventLoopPromise<Void>?) -> Actions

    /// Called when the child channel received a close.
    ///
    /// - Note: This can be used to customize the closing behaviour such as sending out an additional message.
    ///
    /// - Parameters:
    ///   - error: The `Error` why the child channel got closed.
    ///   - mode: The `CloseMode` to apply.
    ///   - promise: The  promise which should be notified once the operation completes, or nil if no notification should take place.
    mutating func childChannelClose(error: Error, mode: CloseMode, promise: EventLoopPromise<Void>?) -> Actions

    /// Called when the last buffered write is immediately followed by a ``CloseMode/output`` close.
    ///
    /// The default implementation calls ``childChannelWriteMessage(_:promise:)`` and
    /// ``childChannelClose(error:mode:promise:)`` independently.  Override this method
    /// to coalesce the final data and the half-close into a single action — for example,
    /// to send data and FIN in one QUIC STREAM frame.
    ///
    /// - Parameters:
    ///   - message: The last outbound message before the output close.
    ///   - writePromise: The promise for the write, or nil.
    ///   - closeError: The error associated with the close.
    ///   - closePromise: The promise for the close, or nil.
    mutating func childChannelWriteAndCloseOutput(
        _ message: ChildChannelOutboundMessage,
        writePromise: EventLoopPromise<Void>?,
        closeError: Error,
        closePromise: EventLoopPromise<Void>?
    ) -> Actions

    /// Called when the child channel executes a previously scheduled task.
    /// This method is being called with the task that is passed in the ``childChannelScheduleTask`` action and allows to
    /// pass values between scheduling and executing.
    ///
    /// - Parameter task: The scheduled task.
    mutating func childChannelExecuteTask(_ task: Task) -> Actions

    // MARK: - Parent channel events

    /// Called when the parent channel became inactive.
    mutating func parentChannelInactive() -> Actions

    /// Called when the parent channel read a message for the child channel.
    ///
    /// - Parameters:
    ///     - message: The message read in the parent channel.
    mutating func parentChannelReadMessage(_ message: ParentChannelInboundMessage) -> Actions

    /// Called when the parent channel has completed all reads for this read event.
    mutating func parentChannelReadComplete() -> Actions

    /// Called when a user inbound event was triggered on the parent channel.
    ///
    /// - Parameter event: The inbound event.
    mutating func parentChannelUserInboundEventTriggered(_ event: Any) -> Actions

    /// Called when an extra channel ID was assigned by the parent channel.
    ///
    /// - Parameter extraChannelID: The extra channel ID that was assigned.
    mutating func extraChannelIDAssigned(_ extraChannelID: ChildChannelID) -> Actions

    /// Called when an extra channel ID was retired by the parent channel.
    ///
    /// - Parameter channelID: The extra channel ID that was retired.
    mutating func channelIDRetired(_ channelID: ChildChannelID) -> Actions
}

extension ChildChannelStateMachine where Task == Never {
    public mutating func childChannelExecuteTask(_: Task) -> Actions {}
}

extension ChildChannelStateMachine where ChildChannelIDProperties == Never {
    public mutating func childChannelIDGenerated(childChannelID: ChildChannelID) -> Actions {
        fatalError("Unimplemented")
    }
}

// Default impl to avoid api break.
extension ChildChannelStateMachine {
    public func childChannelReceivedInputClosed() -> Actions {
        .init(.childChannelFireInputClosed)
    }

    public func extraChannelIDAssigned(_ extraChannelID: ChildChannelID) -> Actions {
        .init()
    }

    public func channelIDRetired(_ channelID: ChildChannelID) -> Actions {
        .init()
    }

    public func parentChannelReadComplete() -> Actions {
        .init()
    }

    public mutating func childChannelWriteAndCloseOutput(
        _ message: ChildChannelOutboundMessage,
        writePromise: EventLoopPromise<Void>?,
        closeError: Error,
        closePromise: EventLoopPromise<Void>?
    ) -> Actions {
        var actions = self.childChannelWriteMessage(message, promise: writePromise)
        for action in self.childChannelClose(error: closeError, mode: .output, promise: closePromise) {
            actions.append(action)
        }
        return actions
    }
}
