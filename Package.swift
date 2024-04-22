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

// https://medium.com/jamf-engineering/swift-6-upgrade-preparation-0941fbea2db6
// Swift 6 upgrade Preparation
// If future target types are also incompatible with swiftSettings then
// the where test will need to be updated.
for target in package.targets where target.type != .binary 
{
 var swiftSettings = target.swiftSettings ?? []
    
 // According to Swift's piecemeal adoption plan features that were
 // upcoming features that become language defaults and are still enabled
 // as upcoming features will result in a compiler error. Currently in the
 // latest 5.10 compiler this doesn't happen, the compiler ignores it.
 //
 // If the situation does change and enabling default language features
 // does result in an error in future versions we attempt to guard against
 // this by using the hasFeature(x) compiler directive to see if we have a
 // feature already, or if we can enable it. It's safe to enable features
 // that don't exist in older compiler versions as the compiler will ignore
 // features it doesn't have implemented.
 
 // swift 6
 #if !hasFeature(ConciseMagicFile)
 swiftSettings.append(.enableUpcomingFeature("ConciseMagicFile"))
 #endif

 #if !hasFeature(ForwardTrailingClosures)
 swiftSettings.append(.enableUpcomingFeature("ForwardTrailingClosures"))
 #endif

 #if !hasFeature(StrictConcurrency)
 swiftSettings.append(.enableUpcomingFeature("StrictConcurrency"))
 // StrictConcurrency is under experimental features in Swift <=5.10 contrary to some posts and documentation
 swiftSettings.append(.enableExperimentalFeature("StrictConcurrency"))
 #endif

 #if !hasFeature(BareSlashRegexLiterals)
 swiftSettings.append(.enableUpcomingFeature("BareSlashRegexLiterals"))
 #endif

 #if !hasFeature(ImplicitOpenExistentials)
 swiftSettings.append(.enableUpcomingFeature("ImplicitOpenExistentials"))
 #endif

 #if !hasFeature(ImportObjcForwardDeclarations)
 swiftSettings.append(.enableUpcomingFeature("ImportObjcForwardDeclarations"))
 #endif

 #if !hasFeature(DisableOutwardActorInference)
 swiftSettings.append(.enableUpcomingFeature("DisableOutwardActorInference"))
 #endif

 #if !hasFeature(InternalImportsByDefault)
 swiftSettings.append(.enableUpcomingFeature("InternalImportsByDefault"))
 #endif
 
 #if !hasFeature(IsolatedDefaultValues)
 swiftSettings.append(.enableUpcomingFeature("IsolatedDefaultValues"))
 #endif
 
 #if !hasFeature(GlobalConcurrency)
 swiftSettings.append(.enableUpcomingFeature("GlobalConcurrency"))
 #endif

 // swift 7
 #if !hasFeature(ExistentialAny)
 swiftSettings.append(.enableUpcomingFeature("ExistentialAny"))
 #endif
 
 target.swiftSettings = swiftSettings
}
