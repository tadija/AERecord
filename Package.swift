// swift-tools-version:4.2

/**
 *  https://github.com/tadija/AERecord
 *  Copyright (c) Marko Tadić 2014-2018
 *  Licensed under the MIT license. See LICENSE file.
 */

import PackageDescription

let package = Package(
    name: "AERecord",
    products: [
        .library(name: "AERecord", targets: ["AERecord"])
    ],
    targets: [
        .target(
            name: "AERecord"
        ),
        .testTarget(
            name: "AERecordTests",
            dependencies: ["AERecord"]
        )
    ]
)
