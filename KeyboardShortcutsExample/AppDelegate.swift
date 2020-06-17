import Cocoa
import SwiftUI
import KeyboardShortcuts

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
	private var window: NSWindow!

	func applicationDidFinishLaunching(_ notification: Notification) {
		let contentView = ContentView()

		window = NSWindow(
			contentRect: CGRect(x: 0, y: 0, width: 480, height: 300),
			styleMask: [
				.titled,
				.closable,
				.miniaturizable,
				.fullSizeContentView
			],
			backing: .buffered,
			defer: false
		)

		window.title = "KeyboardShortcuts Example"
		window.center()
		window.setFrameAutosaveName("Main Window")
		window.contentView = NSHostingView(rootView: contentView)
		window.makeKeyAndOrderFront(nil)

		createMenus()
	}

	func createMenus() {
		let testMenuItem = NSMenuItem()
		NSApp.mainMenu?.addItem(testMenuItem)

		let testMenu = NSMenu()
		testMenu.title = "Test"
		testMenuItem.submenu = testMenu

		let shortcut1 = NSMenuItem()
		shortcut1.title = "Shortcut 1"
		shortcut1.action = #selector(shortcutAction1)
		shortcut1.setShortcut(for: .testShortcut1)
		testMenu.addItem(shortcut1)

		let shortcut2 = NSMenuItem()
		shortcut2.title = "Shortcut 2"
		shortcut2.action = #selector(shortcutAction2)
		shortcut2.setShortcut(for: .testShortcut2)
		testMenu.addItem(shortcut2)
	}

	@objc
	func shortcutAction1(_ sender: NSMenuItem) {
		let alert = NSAlert()
		alert.messageText = "Shortcut 1 menu item action triggered!"
		alert.runModal()
	}

	@objc
	func shortcutAction2(_ sender: NSMenuItem) {
		let alert = NSAlert()
		alert.messageText = "Shortcut 2 menu item action triggered!"
		alert.runModal()
	}
}
