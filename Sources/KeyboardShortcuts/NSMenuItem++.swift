#if os(macOS)
import AppKit

extension NSMenuItem {
	private final class WeakReference<T: AnyObject>: @unchecked Sendable {
		weak var value: T?

		init(_ value: T) {
			self.value = value
		}
	}

	private struct FallbackShortcut: Sendable {
		let keyEquivalent: String
		let modifierMask: NSEvent.ModifierFlags
	}

	private enum AssociatedKeys {
		static let observer = ObjectAssociation<NSObjectProtocol>()
		static let fallback = ObjectAssociation<FallbackShortcut>()
		static let boundName = ObjectAssociation<KeyboardShortcuts.Name>()
	}

	/**
	Returns the shortcut name currently bound with `setShortcut(for:)`.
	*/
	var keyboardShortcutsBoundName: KeyboardShortcuts.Name? {
		AssociatedKeys.boundName[self]
	}

	private func clearShortcut() {
		keyEquivalent = ""
		keyEquivalentModifierMask = []

		if #available(macOS 12, *) {
			allowsAutomaticKeyEquivalentLocalization = true
		}
	}

	private func restoreShortcut() {
		if let fallback = AssociatedKeys.fallback[self] {
			keyEquivalent = fallback.keyEquivalent
			keyEquivalentModifierMask = fallback.modifierMask

			if #available(macOS 12, *) {
				allowsAutomaticKeyEquivalentLocalization = true
			}
		} else {
			clearShortcut()
		}
	}

	private func applyShortcut(_ shortcut: KeyboardShortcuts.Shortcut?) {
		guard let shortcut else {
			clearShortcut()
			return
		}

		keyEquivalent = shortcut.nsMenuItemKeyEquivalent ?? ""
		keyEquivalentModifierMask = shortcut.modifiers

		if #available(macOS 12, *) {
			allowsAutomaticKeyEquivalentLocalization = false
		}
	}

	private func removeShortcutObserver() {
		guard let existingObserver = AssociatedKeys.observer[self] else {
			return
		}

		NotificationCenter.default.removeObserver(existingObserver)
		AssociatedKeys.observer[self] = nil
	}

	// TODO: Make this a getter/setter. We must first add the ability to create a `Shortcut` from a `keyEquivalent`.
	/**
	Show a recorded keyboard shortcut in a `NSMenuItem`.

	The menu item will automatically be kept up to date with changes to the keyboard shortcut.

	Pass in `nil` to clear the keyboard shortcut.

	This method overrides `.keyEquivalent` and `.keyEquivalentModifierMask`. The original values are preserved and restored when the global shortcut is cleared.

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
	public func setShortcut(for name: KeyboardShortcuts.Name?) {
		guard let name else {
			restoreShortcut()
			AssociatedKeys.boundName[self] = nil
			AssociatedKeys.fallback[self] = nil
			removeShortcutObserver()
			return
		}

		if AssociatedKeys.observer[self] != nil {
			removeShortcutObserver()
		} else {
			AssociatedKeys.fallback[self] = FallbackShortcut(
				keyEquivalent: keyEquivalent,
				modifierMask: keyEquivalentModifierMask
			)
		}

		let shortcut = KeyboardShortcuts.Shortcut(name: name)
		if let shortcut {
			applyShortcut(shortcut)
		} else {
			restoreShortcut()
		}

		AssociatedKeys.boundName[self] = name
		let menuItemReference = WeakReference(self)

		// TODO: Use AsyncStream when targeting macOS 15.
		AssociatedKeys.observer[self] = NotificationCenter.default.addObserver(forName: .shortcutByNameDidChange, object: nil, queue: .main) { notification in
			guard
				let nameInNotification = notification.keyboardShortcutsName,
				nameInNotification == name
			else {
				return
			}

			MainActor.assumeIsolated {
				guard let menuItem = menuItemReference.value else {
					return
				}

				let shortcut = KeyboardShortcuts.Shortcut(name: name)
				if let shortcut {
					menuItem.applyShortcut(shortcut)
				} else {
					menuItem.restoreShortcut()
				}
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
	public func setShortcut(_ shortcut: KeyboardShortcuts.Shortcut?) {
		removeShortcutObserver()
		AssociatedKeys.boundName[self] = nil
		applyShortcut(shortcut)
	}
}
#endif
