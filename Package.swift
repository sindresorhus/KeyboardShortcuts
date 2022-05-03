// swift-tools-version:5.6
import PackageDescription

let package = Package(
	name: "KeyboardShortcuts",
	defaultLocalization: "en",
	platforms: [
		.macOS(.v10_11)
	],
	products: [
		.library(
			name: "KeyboardShortcuts",
			targets: [
				"KeyboardShortcuts"
			]
		)
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
	],
	targets: [
		.target(
			name: "KeyboardShortcuts"
		),
		.testTarget(
			name: "KeyboardShortcutsTests",
			dependencies: [
				"KeyboardShortcuts"
			]
		)
	]
)
