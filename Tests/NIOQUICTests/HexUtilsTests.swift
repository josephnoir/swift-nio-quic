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

import XCTest

@testable import NIOQUIC

final class HexUtilsTests: XCTestCase {
    func testCollectionToHexString() {
        var bytes: [UInt8] = []
        XCTAssertEqual(bytes.hexEncoded, "")

        bytes = [0x0]
        XCTAssertEqual(bytes.hexEncoded, "0x00")

        bytes = [0xF, 0xF]
        XCTAssertEqual(bytes.hexEncoded, "0x0f0f")

        bytes = [0xFF, 0xFF]
        XCTAssertEqual(bytes.hexEncoded, "0xffff")

        bytes = [0xDE, 0xAD, 0xBE, 0xEF]
        XCTAssertEqual(bytes.hexEncoded, "0xdeadbeef")

        bytes = Array(repeating: 0xA, count: 10)
        XCTAssertEqual(bytes.hexEncoded, "0x0a0a0a0a0a0a0a0a0a0a")
    }
}
