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

/// State machine tracking the phases of the buffered deletion test.
///
/// This is a straightforward line of state transitions.
/// * waitingForFirstRoundtrip: Perform the first roundtrip to give
///     the implementations time to exchange connection IDs. On the
///     first server response, run `queryActiveSCIDsAndAssociateA` to
///     discover existing connection IDs and associate a new ID A.
/// * waitingForAssociationOfA: Wait for A's `QUICSCIDAssociatedEvent`.
///     When it arrives, run `removeAllSCIDsAndAssociateB` to remove
///     all connection IDs from our internal state (this is the tracking
///     state in Swift NIO QUIC, not the routing state or state in
///     Swift QUIC) and associate a new connection ID B.
/// * waitingForAssociationOfB: Wait for B's `QUICSCIDAssociatedEvent`.
///     B must be associated before A's deferred retirement fires —
///     this is the ordering invariant the test verifies.
/// * waitingForDeferredRetirementOfA: Wait for A's deferred
///     `QUICSCIDRetiredEvent`, which was buffered because A was the
///     last active SCID when it was removed. Mark test as done.
/// * done: Send a message to the server to indicate that the test
///     finished and wait for the response.
/// * shuttingDown: Terminal state. This is where the state machine
///     should be at the end of the test.
///
/// This is used by `TestBufferedDeletionClientHandler` in the
/// `SyncIntegrationTest`.
struct BufferedDeletionStateMachine {
    enum State {
        case waitingForFirstRoundtrip
        case waitingForAssociationOfA
        case waitingForAssociationOfB
        case waitingForDeferredRetirementOfA
        case done
        case shuttingDown
    }

    private var state: State

    init() {
        self.state = .waitingForFirstRoundtrip
    }

    // MARK: - Queries

    var isShuttingDown: Bool {
        switch self.state {
        case .shuttingDown:
            return true
        case .waitingForFirstRoundtrip, .waitingForAssociationOfA,
            .waitingForAssociationOfB, .waitingForDeferredRetirementOfA,
            .done:
            return false
        }
    }

    // MARK: - Transitions

    enum ReceivedResponseAction {
        /// First response received. Handler should query active SCIDs, associate SCID A, and write the next request.
        case queryActiveSCIDsAndAssociateA
        /// Intermediate response. Handler should write another request to keep polling.
        case writeRequest
        /// Test complete. Handler should write the final request and close output.
        case writeFinalRequestAndClose
        /// Nothing to do.
        case noAction
    }

    mutating func receivedResponse() -> ReceivedResponseAction {
        switch self.state {
        case .waitingForFirstRoundtrip:
            self.state = .waitingForAssociationOfA
            return .queryActiveSCIDsAndAssociateA
        case .waitingForAssociationOfA, .waitingForAssociationOfB,
            .waitingForDeferredRetirementOfA:
            return .writeRequest
        case .done:
            self.state = .shuttingDown
            return .writeFinalRequestAndClose
        case .shuttingDown:
            return .noAction
        }
    }

    enum ScidAAssociatedAction {
        /// Handler should remove all initial SCIDs, remove A (buffered as last), and associate B.
        case removeAllSCIDsAndAssociateB
        /// Unexpected state.
        case unexpectedState
    }

    mutating func scidAAssociated() -> ScidAAssociatedAction {
        switch self.state {
        case .waitingForAssociationOfA:
            self.state = .waitingForAssociationOfB
            return .removeAllSCIDsAndAssociateB
        case .waitingForFirstRoundtrip, .waitingForAssociationOfB,
            .waitingForDeferredRetirementOfA, .done, .shuttingDown:
            return .unexpectedState
        }
    }

    enum ScidBAssociatedAction {
        /// Transition succeeded. No side effects needed.
        case noAction
        /// Unexpected state.
        case unexpectedState
    }

    mutating func scidBAssociated() -> ScidBAssociatedAction {
        switch self.state {
        case .waitingForAssociationOfB:
            self.state = .waitingForDeferredRetirementOfA
            return .noAction
        case .waitingForFirstRoundtrip, .waitingForAssociationOfA,
            .waitingForDeferredRetirementOfA, .done, .shuttingDown:
            return .unexpectedState
        }
    }

    enum ScidARetiredAction {
        /// Transition succeeded. No side effects needed.
        case noAction
        /// Unexpected state.
        case unexpectedState
    }

    mutating func scidARetired() -> ScidARetiredAction {
        switch self.state {
        case .waitingForDeferredRetirementOfA:
            self.state = .done
            return .noAction
        case .waitingForFirstRoundtrip, .waitingForAssociationOfA,
            .waitingForAssociationOfB, .done, .shuttingDown:
            return .unexpectedState
        }
    }
}
