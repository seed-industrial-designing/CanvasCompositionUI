// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "CanvasCompositionUI",
	defaultLocalization: "en",
	platforms: [.macOS(.v12), .iOS(.v15)],
	products: [
		.library(
			name: "CanvasCompositionUI",
			targets: ["CanvasCompositionUI"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/seed-industrial-designing/PrintModelMac.git", from: "1.0.0"),
		.package(url: "https://github.com/zumuya/InlineLocalization.git", from: "1.0.0"),
		.package(url: "https://github.com/zumuya/YokuAruUI.git", from: "1.0.0"),
	],
	targets: [
		.target(
			name: "CanvasCompositionUI",
			dependencies: [
				.product(name: "PrintModel", package: "PrintModelMac"),
				.product(name: "InlineLocalization", package: "InlineLocalization"),
				.product(name: "YokuAruUI", package: "YokuAruUI"),
			],
			path: "Sources"
		)
	]
)
