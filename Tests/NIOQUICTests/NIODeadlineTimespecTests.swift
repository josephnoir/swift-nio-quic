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
import XCTest

@testable import NIOQUIC

final class NIODeadlineTimespectTests: XCTestCase {
    func testDeadlineFromTimespec() {
        let ts = timespec(tv_sec: 3, tv_nsec: 141_592_653)
        let deadline = NIODeadline(timespec: ts)
        XCTAssertEqual(deadline, .uptimeNanoseconds(3_141_592_653))
    }

    func testDeadlineFromZeroSeconds() {
        let ts = timespec(tv_sec: 0, tv_nsec: 42)
        let deadline = NIODeadline(timespec: ts)
        XCTAssertEqual(deadline, .uptimeNanoseconds(42))
    }

    func testDeadlineFromZeroNanoseconds() {
        let ts = timespec(tv_sec: 42, tv_nsec: 0)
        let deadline = NIODeadline(timespec: ts)
        XCTAssertEqual(deadline, .uptimeNanoseconds(42_000_000_000))
    }
}
