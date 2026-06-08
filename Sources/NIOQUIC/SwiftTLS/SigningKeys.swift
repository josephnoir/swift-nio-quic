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

import Crypto
import Foundation

extension P256.Signing.PrivateKey {
    static func fromDERFile(_ path: String) throws -> P256.Signing.PrivateKey {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try .init(derRepresentation: Array(data))
    }
}

extension P256.Signing.PublicKey {
    static func fromDERFile(_ path: String) throws -> P256.Signing.PublicKey {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try .init(derRepresentation: Array(data))
    }
}
