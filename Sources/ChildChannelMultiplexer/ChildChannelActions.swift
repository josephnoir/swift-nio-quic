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

/// A collection that can store ``ChildChannelAction``s.
public struct ChildChannelActions<
    ParentInboundMessage,
    ParentOutboundMessage,
    ChildInboundMessage,
    ChildOutboundMessage,
    Task
> {
    public typealias Action = ChildChannelAction<
        ParentInboundMessage, ParentOutboundMessage, ChildInboundMessage, ChildOutboundMessage, Task
    >

    /// The stack allocated part of the storage.
    // swift-format-ignore: UseShorthandTypeNames
    @usableFromInline
    var stackStorage:
        (
            // Important these need to stay `Optional<Action>` otherwise the compiler won't be able to
            // optimize the array literal init.
            Optional<Action>, Optional<Action>, Optional<Action>
        )
    @inlinable
    var stackStorageSize: Int { 3 }

    /// The tail storage that is allocated on the heap.
    @usableFromInline
    var heapStorage: Optional<[Action]>

    /// This is the start index offset used when accessing the `heapStorage` property.
    @inlinable
    var heapStorageStartIndexOffset: Int { self.stackStorageSize }

    /// The number of elements in the collection.
    @usableFromInline
    var _count: Int

    /// Creates a new empty ``ChildChannelActions`` collection..
    @inlinable
    public init() {
        self.stackStorage = (
            nil, nil, nil
        )
        self.heapStorage = []
        self._count = 0
    }

    /// Adds a new action at the end of the collection.
    ///
    /// - Parameter newElement: The action to append to the collection.
    ///
    /// - Complexity: O(1) on average, over many calls to `append(_:)` on the
    ///   same collection.
    @inlinable
    public mutating func append(_ newElement: Action) {
        self._count += 1

        if self._count <= self.stackStorageSize {
            self[self._count &- 1] = newElement
        } else {
            if self.heapStorage == nil {
                self.heapStorage = []
            }
            self.heapStorage!.append(newElement)
        }
    }
}

@available(*, unavailable)
extension ChildChannelActions: Sendable {}

extension ChildChannelActions {
    @inlinable
    public init(
        _ a0: Action
    ) {
        self.init(
            count: 1,
            stackStorage: (a0, nil, nil)
        )
    }

    @inlinable
    public init(
        _ a0: Action,
        _ a1: Action
    ) {
        self.init(
            count: 2,
            stackStorage: (a0, a1, nil)
        )
    }

    @inlinable
    public init(
        _ a0: Action,
        _ a1: Action,
        _ a2: Action
    ) {
        self.init(
            count: 3,
            stackStorage: (a0, a1, a2)
        )
    }

    @inlinable
    public init(
        _ a0: Action,
        _ a1: Action,
        _ a2: Action,
        _ a3: Action
    ) {
        self.init(
            count: 4,
            stackStorage: (a0, a1, a2),
            heapStorage: [a3]
        )
    }

    @inlinable
    public init(
        _ a0: Action,
        _ a1: Action,
        _ a2: Action,
        _ a3: Action,
        _ a4: Action
    ) {
        self.init(
            count: 5,
            stackStorage: (a0, a1, a2),
            heapStorage: [a3, a4]
        )
    }

    @inlinable
    public init(
        _ a0: Action,
        _ a1: Action,
        _ a2: Action,
        _ a3: Action,
        _ a4: Action,
        _ a5: Action
    ) {
        self.init(
            count: 6,
            stackStorage: (a0, a1, a2),
            heapStorage: [a3, a4, a5]
        )
    }

    @inlinable
    public init(
        _ a0: Action,
        _ a1: Action,
        _ a2: Action,
        _ a3: Action,
        _ a4: Action,
        _ a5: Action,
        _ a6: Action
    ) {
        self.init(
            count: 7,
            stackStorage: (a0, a1, a2),
            heapStorage: [a3, a4, a5, a6]
        )
    }

    @inlinable
    public init(
        _ a0: Action,
        _ a1: Action,
        _ a2: Action,
        _ a3: Action,
        _ a4: Action,
        _ a5: Action,
        _ a6: Action,
        _ a7: Action
    ) {
        self.init(
            count: 8,
            stackStorage: (a0, a1, a2),
            heapStorage: [a3, a4, a5, a6, a7]
        )
    }

    @inlinable
    public init(
        _ a0: Action,
        _ a1: Action,
        _ a2: Action,
        _ a3: Action,
        _ a4: Action,
        _ a5: Action,
        _ a6: Action,
        _ a7: Action,
        _ a8: Action
    ) {
        self.init(
            count: 9,
            stackStorage: (a0, a1, a2),
            heapStorage: [a3, a4, a5, a6, a7, a8]
        )
    }

    @inlinable
    public init(
        _ a0: Action,
        _ a1: Action,
        _ a2: Action,
        _ a3: Action,
        _ a4: Action,
        _ a5: Action,
        _ a6: Action,
        _ a7: Action,
        _ a8: Action,
        _ a9: Action
    ) {
        self.init(
            count: 10,
            stackStorage: (a0, a1, a2),
            heapStorage: [a3, a4, a5, a6, a7, a8, a9]
        )
    }

    @inlinable
    internal init(
        count: Int,
        stackStorage: (
            Action?, Action?, Action?
        ),
        heapStorage: [Action]? = nil
    ) {
        self._count = count
        self.stackStorage = stackStorage
        self.heapStorage = heapStorage
    }
}

// MARK: - Conformance to `RandomAccessCollection` & `MutableCollection`

extension ChildChannelActions: RandomAccessCollection, MutableCollection {
    public typealias Index = Int

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(actions: self)
    }

    public struct Iterator: IteratorProtocol {
        public typealias Element = Action

        @usableFromInline
        let _actions: ChildChannelActions
        @usableFromInline
        var _index: Index

        @usableFromInline
        init(actions: ChildChannelActions) {
            self._actions = actions
            self._index = actions.startIndex
        }

        @inlinable
        public mutating func next() -> Element? {
            if self._index == self._actions.endIndex {
                return nil
            }

            defer {
                self._index &+= 1
            }

            return self._actions[self._index]
        }
    }

    @inlinable
    public var startIndex: Index {
        0
    }

    @inlinable
    public var endIndex: Index {
        self._count
    }

    @inlinable
    public var count: Int {
        self._count
    }

    @inlinable
    public subscript(i: Index) -> Action {
        get {
            precondition(i >= self.startIndex && i < self.endIndex, "Index out of range")

            guard i < self.stackStorageSize else {
                // This force unwrap is safe since we are preconditioning before.
                // The unchecked math is safe because we already bounds-checked this.
                return self.heapStorage![i &- self.heapStorageStartIndexOffset]
            }
            switch i {
            case 0:
                return self.stackStorage.0!
            case 1:
                return self.stackStorage.1!
            case 2:
                return self.stackStorage.2!
            default:
                fatalError()
            }
        }
        set {
            precondition(i >= self.startIndex && i < self.endIndex, "Index out of range")

            if i < self.stackStorageSize {
                switch i {
                case 0:
                    self.stackStorage.0 = newValue
                case 1:
                    self.stackStorage.1 = newValue
                    return
                case 2:
                    self.stackStorage.2 = newValue
                    return
                default:
                    fatalError()
                }
            } else {
                // This force unwrap is safe since we are preconditioning before.
                // The unchecked math is safe because we already bounds-checked this.
                self.heapStorage![i &- self.heapStorageStartIndexOffset] = newValue
            }
        }
    }

    @inlinable
    public func index(after i: Index) -> Index {
        i &+ 1
    }

    @inlinable
    public func index(before i: Index) -> Index {
        i &- 1
    }
}

// MARK: - CustomDebugStringConvertible

extension ChildChannelActions: CustomDebugStringConvertible {
    public var debugDescription: String {
        self.map { $0.action.debugDescription }.joined(separator: ", ")
    }
}

@available(*, unavailable)
extension ChildChannelActions.Iterator: Sendable {}
