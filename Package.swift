// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "VLPagedViewKit",
                      platforms: [ .iOS(.v17) ],
                      products:
                      [
                       .library(name: "VLPagedViewKit",
                                targets: [ "VLPagedViewKit" ])
                      ],
                      targets:
                      [
                       .target(name: "VLPagedViewKit"),
                       .testTarget(name: "VLPagedViewTestsKit",
                                   dependencies: [ "VLPagedViewKit" ])
                      ])
