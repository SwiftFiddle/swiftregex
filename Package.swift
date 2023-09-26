// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "swiftregex",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-experimental-string-processing.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-syntax", branch: "main"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.84.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.2.4"),
    ],
    targets: [
        .executableTarget(
            name: "BuilderTester",
            dependencies: [
                .product(name: "_StringProcessing", package: "swift-experimental-string-processing"),
                .product(name: "_RegexParser", package: "swift-experimental-string-processing"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"]),
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(
            name: "DSLConverter",
            dependencies: [
                .product(name: "_StringProcessing", package: "swift-experimental-string-processing"),
                .product(name: "_RegexParser", package: "swift-experimental-string-processing"),
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"]),
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(
            name: "DSLParser",
            dependencies: [
                .product(name: "_StringProcessing", package: "swift-experimental-string-processing"),
                .product(name: "_RegexParser", package: "swift-experimental-string-processing"),
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"]),
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(
            name: "ExpressionParser",
            dependencies: [
                .product(name: "_StringProcessing", package: "swift-experimental-string-processing"),
                .product(name: "_RegexParser", package: "swift-experimental-string-processing"),
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"]),
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(
            name: "Matcher",
            dependencies: [
                .product(name: "_StringProcessing", package: "swift-experimental-string-processing"),
                .product(name: "_RegexParser", package: "swift-experimental-string-processing"),
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"]),
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Leaf", package: "leaf"),
            ],
            swiftSettings: [
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "RegexTests", dependencies: [
                .target(name: "BuilderTester"),
                .target(name: "DSLConverter"),
                .target(name: "DSLParser"),
                .target(name: "ExpressionParser"),
                .target(name: "Matcher"),
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ]
        )
    ]
)
