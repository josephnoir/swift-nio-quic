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

import NIOQUICHelpers

extension NIOQUICHelpers.QUICApplicationErrorCode {
    /// Test-only non-failable convenience. Test values are known-valid constants.
    /// Production code should use the failable `init?(_:)` instead.
    init(_ code: UInt64) {
        self = NIOQUICHelpers.QUICApplicationErrorCode(code)!
    }
}
