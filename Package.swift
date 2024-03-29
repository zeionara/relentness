// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "relentness",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/zeionara/wicked-data", branch: "master"),
        // .package(url: "/home/zeio/wicked-data", branch: "master"),
        // .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.1"),
        .package(url: "https://github.com/zeionara/Yams.git", .branch("main")),
        // .package(url: "/home/zeio/ahsheet", .branch("oauth")),
        .package(url: "https://github.com/zeionara/ahsheet.git", .branch("oauth")),
        .package(url: "https://github.com/zeionara/telegram-bot-swift.git", branch: "master"),
        .package(url: "https://github.com/zeionara/Swat.git", branch: "master"),
        // .package(url: "https://github.com/zeionara/ahsheet.git", .branch("oauth"))
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        // .package(url: "https://github.com/wickwirew/Runtime.git", branch: "master")
        .package(url: "https://github.com/apple/swift-collections.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "relentness",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "wickedData", package: "wicked-data"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "ahsheet", package: "ahsheet"),
                .product(name: "TelegramBotSDK", package: "telegram-bot-swift"),
                .product(name: "OrderedCollections", package: "swift-collections"),
                "Swat"
                // "Runtime"
            ]),
        .testTarget(
            name: "relentnessTests",
            dependencies: ["relentness"]),
    ]
)
