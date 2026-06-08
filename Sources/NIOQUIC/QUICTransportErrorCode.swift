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

enum QUICTransportErrorCode: Int64, Hashable, Sendable {
    case noError = 0x0000
    case internalError = 0x0001
    case connectionRefused = 0x0002
    case flowControlError = 0x0003
    case streamLimitError = 0x0004
    case streamStateError = 0x0005
    case finalSizeError = 0x0006
    case frameEncodingError = 0x0007
    case transportParameterError = 0x0008
    case connectionIDLimitError = 0x0009
    case protocolViolation = 0x000A
    case invalidToken = 0x000B
    case applicationError = 0x000C
    case cryptoBufferExceeded = 0x000D
    case keyUpdateError = 0x000E
    case aeadLimitReached = 0x000F
    case noViablePath = 0x0010
}
