import Cocoa

extension NSMenuItem {
	private struct AssociatedKeys {
		static let observer = ObjectAssociation<NSObjectProtocol>()
	}

	// TODO: Make this a getter/setter. We must first add the ability to create a `Shortcut` from a `keyEquivalent`.
	/**
	Show a recorded keyboard shortcut in a `NSMenuItem`.

	The menu item will automatically be kept up to date with changes to the keyboard shortcut.

	Pass in `nil` to clear the keyboard shortcut.

	This method overrides `.keyEquivalent` and `.keyEquivalentModifierMask`.

	```
	import Cocoa
	import KeyboardShortcuts

	extension KeyboardShortcuts.Name {
		static let toggleUnicornMode = Name("toggleUnicornMode")
	}

	// … `Recorder` logic for recording the keyboard shortcut …

	let menuItem = NSMenuItem()
	menuItem.title = "Toggle Unicorn Mode"
	menuItem.setShortcut(for: .toggleUnicornMode)
	```

	You can test this method in the example project. Run it, record a shortcut and then look at the “Test” menu in the app's main menu.
	*/
	public func setShortcut(for name: KeyboardShortcuts.Name?) {
		func clear() {
			keyEquivalent = ""
			keyEquivalentModifierMask = []
		}

		guard let name = name else {
			clear()
			AssociatedKeys.observer[self] = nil
			return
		}

		func set() {
			guard let shortcut = KeyboardShortcuts.Shortcut(name: name) else {
				clear()
				return
			}

			keyEquivalent = shortcut.keyEquivalent
			keyEquivalentModifierMask = shortcut.modifiers
		}

		set()

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
}
