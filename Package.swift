// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LazyBill",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "LazyBillCore", targets: ["LazyBillCore"])
    ],
    targets: [
        .target(name: "LazyBillCore"),
        .testTarget(name: "LazyBillCoreTests", dependencies: ["LazyBillCore"])
    ]
)
