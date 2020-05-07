import Cocoa
import SwiftUI

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
	var window: NSWindow!

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
	}
}
