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

final class QUICConnectionChannelOutboundMessageTests: XCTestCase {
    func testFlowControlSize() {
        let message = "message"

        let data = QUICConnectionChannelOutboundMessage(
            streamID: .init(rawValue: 0),
            streamMessage: .init(
                data: ByteBuffer(string: message),
                fin: false
            )
        )

        XCTAssertEqual(data.flowControlSize, message.utf8.count)
    }
}
