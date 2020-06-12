// swift-tools-version:5.0
import PackageDescription

let package = Package(
  name: "SubtleVolume",
  products: [
    .library(
      name: "SubtleVolume",
      targets: ["SubtleVolume"])
  ],
  targets: [
    .target(
      name: "SubtleVolume",
      path: "Source")
  ]
)