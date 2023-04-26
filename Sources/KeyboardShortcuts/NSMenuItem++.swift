import AppKit

extension NSMenuItem {
	private enum AssociatedKeys {
		static let observer = ObjectAssociation<NSObjectProtocol>()
	}

	private func clearShortcut() {
		keyEquivalent = ""
		keyEquivalentModifierMask = []

		if #available(macOS 12, *) {
			allowsAutomaticKeyEquivalentLocalization = true
		}
	}

	// TODO: Make this a getter/setter. We must first add the ability to create a `Shortcut` from a `keyEquivalent`.
	/**
	Show a recorded keyboard shortcut in a `NSMenuItem`.

	The menu item will automatically be kept up to date with changes to the keyboard shortcut.

	Pass in `nil` to clear the keyboard shortcut.

	This method overrides `.keyEquivalent` and `.keyEquivalentModifierMask`.

	```swift
	import Cocoa
	import KeyboardShortcuts

	extension KeyboardShortcuts.Name {
		static let toggleUnicornMode = Self("toggleUnicornMode")
	}

	// … `Recorder` logic for recording the keyboard shortcut …

	let menuItem = NSMenuItem()
	menuItem.title = "Toggle Unicorn Mode"
	menuItem.setShortcut(for: .toggleUnicornMode)
	```

	You can test this method in the example project. Run it, record a shortcut and then look at the “Test” menu in the app's main menu.

	- Important: You will have to disable the global keyboard shortcut while the menu is open, as otherwise, the keyboard events will be buffered up and triggered when the menu closes. This is because `NSMenu` puts the thread in tracking-mode, which prevents the keyboard events from being received. You can listen to whether a menu is open by implementing `NSMenuDelegate#menuWillOpen` and `NSMenuDelegate#menuDidClose`. You then use `KeyboardShortcuts.disable` and `KeyboardShortcuts.enable`.
	*/
	public func setShortcut(for name: KeyboardShortcuts.Name?) {
		guard let name else {
			clearShortcut()
			AssociatedKeys.observer[self] = nil
			return
		}

		func set() {
			let shortcut = KeyboardShortcuts.Shortcut(name: name)
			setShortcut(shortcut)
		}

		set()

		// TODO: Use AsyncStream when targeting macOS 10.15.
		AssociatedKeys.observer[self] = NotificationCenter.default.addObserver(forName: .shortcutByNameDidChange, object: nil, queue: nil) { notification in
			guard
				let nameInNotification = notification.userInfo?["name"] as? KeyboardShortcuts.Name,
				nameInNotification == name
			else {
				return
			}

			set()
		}
	}

	/**
	Add a keyboard shortcut to a `NSMenuItem`.

	This method is only recommended for dynamic shortcuts. In general, it's preferred to create a static shortcut name and use `NSMenuItem.setShortcut(for:)` instead.

	Pass in `nil` to clear the keyboard shortcut.

	This method overrides `.keyEquivalent` and `.keyEquivalentModifierMask`.

	- Important: You will have to disable the global keyboard shortcut while the menu is open, as otherwise, the keyboard events will be buffered up and triggered when the menu closes. This is because `NSMenu` puts the thread in tracking-mode, which prevents the keyboard events from being received. You can listen to whether a menu is open by implementing `NSMenuDelegate#menuWillOpen` and `NSMenuDelegate#menuDidClose`. You then use `KeyboardShortcuts.disable` and `KeyboardShortcuts.enable`.
	*/
	@_disfavoredOverload
	public func setShortcut(_ shortcut: KeyboardShortcuts.Shortcut?) {
		func set() {
			guard let shortcut else {
				clearShortcut()
				return
			}

			keyEquivalent = shortcut.keyEquivalent
			keyEquivalentModifierMask = shortcut.modifiers

			if #available(macOS 12, *) {
				allowsAutomaticKeyEquivalentLocalization = false
			}
		}

		// `TISCopyCurrentASCIICapableKeyboardLayoutInputSource` works on a background thread, but crashes when used in a `NSBackgroundActivityScheduler` task, so we ensure it's not run in that queue.
		if DispatchQueue.isCurrentQueueNSBackgroundActivitySchedulerQueue {
			DispatchQueue.main.async {
				set()
			}
		} else {
			set()
		}
	}
}
