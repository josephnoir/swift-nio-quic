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
let nibbleToHexChar: [UInt8] = [
    UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "2"), UInt8(ascii: "3"),
    UInt8(ascii: "4"), UInt8(ascii: "5"), UInt8(ascii: "6"), UInt8(ascii: "7"),
    UInt8(ascii: "8"), UInt8(ascii: "9"), UInt8(ascii: "a"), UInt8(ascii: "b"),
    UInt8(ascii: "c"), UInt8(ascii: "d"), UInt8(ascii: "e"), UInt8(ascii: "f"),
]

extension Collection<UInt8> {
    @inlinable
    @available(macOS 11, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *)
    var hexEncoded: String {
        if self.isEmpty {
            return ""
        }

        return String(unsafeUninitializedCapacity: (2 * self.count) + 2) { ptr in
            precondition(ptr.count >= (2 * self.count) + 2)
            var index = ptr.startIndex
            ptr[index] = UInt8(ascii: "0")
            ptr.formIndex(after: &index)
            ptr[index] = UInt8(ascii: "x")
            ptr.formIndex(after: &index)

            for byte in self {
                ptr[index] = nibbleToHexChar[Int(byte >> 4)]
                ptr.formIndex(after: &index)
                ptr[index] = nibbleToHexChar[Int(byte & 0b1111)]
                ptr.formIndex(after: &index)
            }

            return index
        }
    }
}
