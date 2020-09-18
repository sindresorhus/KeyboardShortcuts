// swift-tools-version:5.3
import PackageDescription

let package = Package(
	name: "KeyboardShortcuts",
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
	targets: [
		.target(
			name: "KeyboardShortcuts"
		)
	]
)
