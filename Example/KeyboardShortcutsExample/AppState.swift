import AppKit

final class AppState {
	static let shared = AppState()

	private init() {}

	func alert(_ number: Int) {
		let alert = NSAlert()
		alert.messageText = "Shortcut \(number) menu item action triggered!"
		alert.runModal()
	}
}
