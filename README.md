# SwiftNIO QUIC

SwiftNIO QUIC provides bindings between [SwiftNIO][swift-nio] and a Swift
implementation of the QUIC network protocol from
[Swift Network Evolution][swift-network]. It makes use
of [Swift TLS][swift-tls] and [SwiftNIO QUIC Helpers][swift-nio-quic-helpers]
and integrates with [SwiftNIO HTTP/3][swift-nio-http3].

> [!IMPORTANT]
> This package is still in active development and does not offer a stable API
> yet.

## Quick Start

The following snippet contains a Swift Package manifest to use SwiftNIO QUIC:

```swift
// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "Application",
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.100.0"),
        .package(url: "https://github.com/apple/swift-nio-quic", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "QUICServer",
            dependencies: [
                .product(name: "NIOQUIC", package: "swift-nio-quic"),
                .product(name: "NIOCore", package: "swift-nio"),
            ]
        )
    ]
)
```

## Getting Started

### Prerequisites

- [Swift 6.3 and up](https://swift.org/install)
- macOS 26.0 and up or Linux (Ubuntu 22.04+)
- Xcode 26.0 and up (Apple platforms only)

### Building and testing

To build via the command line (for all platforms), run at the root of the
package:

```
swift build
```

To run all unit tests, run

```
swift test
```

Unit tests can also be run by filtering a specific class or function:

```
swift test --filter QUICConnectionIDTests
swift test --filter QUICConnectionIDTests.testZeroLengthConnectionID
```

[swift-nio]: https://github.com/apple/swift-nio
[swift-nio-quic-helpers]: https://github.com/apple/swift-nio-quic-helpers
[swift-nio-http3]: https://github.com/apple/swift-nio-http3
[swift-network]: https://github.com/apple/swift-network-evolution
[swift-tls]: https://github.com/apple/swift-tls
