// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "midnight",
    platforms: [
        .macOS(.v10_15),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
        .package(url: "https://github.com/nodes-vapor/gatekeeper.git", from: "4.0.0"),
        // For https://github.com/slashmo/swift-app-store-receipt-validation
        .package(url: "https://github.com/swift-server/async-http-client", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/apple/swift-nio", .upToNextMajor(from: "2.14.0")),
        // I got tired of trying to make Vapor expose its underlying Swift NIO bits -- Ultimately it's easier to re-write the receipt validation package's Client class to just use Vapor directly.  smh.
        //.package(url: "https://github.com/slashmo/swift-app-store-receipt-validation", .upToNextMajor(from: "0.1.0")),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Gatekeeper", package: "gatekeeper"),
                // For https://github.com/slashmo/swift-app-store-receipt-validation
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                //.product(name: "AppStoreReceiptValidation", package: "swift-app-store-receipt-validation"),
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
