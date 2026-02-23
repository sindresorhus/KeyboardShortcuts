// swift-tools-version:6.2
import PackageDescription

let package = Package(
	name: "KeyboardShortcuts",
	defaultLocalization: "en",
	platforms: [
		.macOS(.v10_15)
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
			name: "KeyboardShortcuts",
			swiftSettings: [
				.defaultIsolation(MainActor.self),
				.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
				.enableUpcomingFeature("InferIsolatedConformances")
			]
		),
		.testTarget(
			name: "KeyboardShortcutsTests",
			dependencies: [
				"KeyboardShortcuts"
			],
			swiftSettings: [
				.defaultIsolation(MainActor.self),
				.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
				.enableUpcomingFeature("InferIsolatedConformances")
			]
		)
	]
)
