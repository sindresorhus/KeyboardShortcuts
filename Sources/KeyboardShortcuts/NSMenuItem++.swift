#if os(macOS)
import AppKit

extension NSMenuItem {
	private enum AssociatedKeys {
		@MainActor
		static let observer = ObjectAssociation<NSObjectProtocol>()
	}

	@MainActor
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
	import AppKit
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
	@MainActor
	public func setShortcut(for name: KeyboardShortcuts.Name?) {
		guard let name else {
			clearShortcut()
			NotificationCenter.default.removeObserver(AssociatedKeys.observer[self] as Any)
			AssociatedKeys.observer[self] = nil
			return
		}

		func set() {
			let shortcut = KeyboardShortcuts.Shortcut(name: name)
			setShortcut(shortcut)
		}

		set()

		// TODO: Use AsyncStream when targeting macOS 15.
		AssociatedKeys.observer[self] = NotificationCenter.default.addObserver(forName: .shortcutByNameDidChange, object: nil, queue: nil) { notification in
			guard
				let nameInNotification = notification.userInfo?["name"] as? KeyboardShortcuts.Name,
				nameInNotification == name
			else {
				return
			}

			DispatchQueue.main.async { // TODO: Use `Task { @MainActor`
				set()
			}
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
	@MainActor
	public func setShortcut(_ shortcut: KeyboardShortcuts.Shortcut?) {
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
}
#endif
