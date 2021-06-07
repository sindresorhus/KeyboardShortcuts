import Cocoa

/**
Global keyboard shortcuts for your macOS app.
*/
public enum KeyboardShortcuts {
	/// :nodoc:
	public typealias KeyAction = () -> Void

	private static var registeredShortcuts = Set<Shortcut>()

	// Not currently used. For the future.
	private static var keyDownHandlers = [Shortcut: [KeyAction]]()
	private static var keyUpHandlers = [Shortcut: [KeyAction]]()

	private static var userDefaultsKeyDownHandlers = [Name: [KeyAction]]()
	private static var userDefaultsKeyUpHandlers = [Name: [KeyAction]]()

	/// When `true`, event handlers will not be called for registered keyboard shortcuts.
	static var isPaused = false

	private static func register(_ shortcut: Shortcut) {
		guard !registeredShortcuts.contains(shortcut) else {
			return
		}

		CarbonKeyboardShortcuts.register(
			shortcut,
			onKeyDown: handleOnKeyDown,
			onKeyUp: handleOnKeyUp
		)

		registeredShortcuts.insert(shortcut)
	}

	private static func unregister(_ shortcut: Shortcut) {
		CarbonKeyboardShortcuts.unregister(shortcut)
		registeredShortcuts.remove(shortcut)
	}

	// TODO: Doc comment and make this public.
	static func unregisterAll() {
		CarbonKeyboardShortcuts.unregisterAll()
		registeredShortcuts.removeAll()

		// TODO: Should remove user defaults too.
	}

	/**
	Remove all handlers receiving keyboard shortcuts events.

	This can be used to reset the handlers before re-creating them to avoid having multiple handlers for the same shortcut.
	*/
	public static func removeAllHandlers() {
		CarbonKeyboardShortcuts.unregisterAll()
		keyDownHandlers = [:]
		keyUpHandlers = [:]
		userDefaultsKeyDownHandlers = [:]
		userDefaultsKeyUpHandlers = [:]
	}

	// TODO: Also add `.isEnabled(_ name: Name)`.
	/**
	Disable a keyboard shortcut.
	*/
	public static func disable(_ name: Name) {
		guard let shortcut = getShortcut(for: name) else {
			return
		}

		unregister(shortcut)
	}

	/**
	Enable a disabled keyboard shortcut.
	*/
	public static func enable(_ name: Name) {
		guard let shortcut = getShortcut(for: name) else {
			return
		}

		register(shortcut)
	}

	/**
	Reset the keyboard shortcut for one or more names.

	If the `Name` has a default shortcut, it will reset to that.

	```
	import SwiftUI
	import KeyboardShortcuts

	struct PreferencesView: View {
		var body: some View {
			VStack {
				// …
				Button("Reset All") {
					KeyboardShortcuts.reset(
						.toggleUnicornMode,
						.showRainbow
					)
				}
			}
		}
	}
	```
	*/
	public static func reset(_ names: Name...) {
		reset(names)
	}

	/**
	Reset the keyboard shortcut for one or more names.

	If the `Name` has a default shortcut, it will reset to that.

	- Note: This overload exists as Swift doesn't support splatting.

	```
	import SwiftUI
	import KeyboardShortcuts

	struct PreferencesView: View {
		var body: some View {
			VStack {
				// …
				Button("Reset All") {
					KeyboardShortcuts.reset(
						.toggleUnicornMode,
						.showRainbow
					)
				}
			}
		}
	}
	```
	*/
	public static func reset(_ names: [Name]) {
		for name in names {
			setShortcut(name.defaultShortcut, for: name)
		}
	}

	/**
	Set the keyboard shortcut for a name.

	Setting it to `nil` removes the shortcut, even if the `Name` has a default shortcut defined. Use `.reset()` if you want it to respect the default shortcut.

	You would usually not need this as the user would be the one setting the shortcut in a preferences user-interface, but it can be useful when, for example, migrating from a different keyboard shortcuts package.
	*/
	public static func setShortcut(_ shortcut: Shortcut?, for name: Name) {
		guard let shortcut = shortcut else {
			userDefaultsRemove(name: name)
			return
		}

		userDefaultsSet(name: name, shortcut: shortcut)
	}

	/**
	Get the keyboard shortcut for a name.
	*/
	public static func getShortcut(for name: Name) -> Shortcut? {
		guard
			let data = UserDefaults.standard.string(forKey: userDefaultsKey(for: name))?.data(using: .utf8),
			let decoded = try? JSONDecoder().decode(Shortcut.self, from: data)
		else {
			return nil
		}

		return decoded
	}

	private static func handleOnKeyDown(_ shortcut: Shortcut) {
		guard !isPaused else {
			return
		}

		if let handlers = keyDownHandlers[shortcut] {
			for handler in handlers {
				handler()
			}
		}

		for (name, handlers) in userDefaultsKeyDownHandlers {
			guard getShortcut(for: name) == shortcut else {
				continue
			}

			for handler in handlers {
				handler()
			}
		}
	}

	private static func handleOnKeyUp(_ shortcut: Shortcut) {
		guard !isPaused else {
			return
		}

		if let handlers = keyUpHandlers[shortcut] {
			for handler in handlers {
				handler()
			}
		}

		for (name, handlers) in userDefaultsKeyUpHandlers {
			guard getShortcut(for: name) == shortcut else {
				continue
			}

			for handler in handlers {
				handler()
			}
		}
	}

	/**
	Listen to the keyboard shortcut with the given name being pressed.

	You can register multiple listeners.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	```
	import Cocoa
	import KeyboardShortcuts

	@main
	final class AppDelegate: NSObject, NSApplicationDelegate {
		func applicationDidFinishLaunching(_ notification: Notification) {
			KeyboardShortcuts.onKeyDown(for: .toggleUnicornMode) { [self] in
				isUnicornMode.toggle()
			}
		}
	}
	```
	*/
	public static func onKeyDown(for name: Name, action: @escaping KeyAction) {
		if userDefaultsKeyDownHandlers[name] == nil {
			userDefaultsKeyDownHandlers[name] = []
		}

		userDefaultsKeyDownHandlers[name]?.append(action)

		// If the keyboard shortcut already exist, we register it.
		if let shortcut = getShortcut(for: name) {
			register(shortcut)
		}
	}

	/**
	Listen to the keyboard shortcut with the given name being pressed.

	You can register multiple listeners.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	```
	import Cocoa
	import KeyboardShortcuts

	@main
	final class AppDelegate: NSObject, NSApplicationDelegate {
		func applicationDidFinishLaunching(_ notification: Notification) {
			KeyboardShortcuts.onKeyUp(for: .toggleUnicornMode) { [self] in
				isUnicornMode.toggle()
			}
		}
	}
	```
	*/
	public static func onKeyUp(for name: Name, action: @escaping KeyAction) {
		if userDefaultsKeyUpHandlers[name] == nil {
			userDefaultsKeyUpHandlers[name] = []
		}

		userDefaultsKeyUpHandlers[name]?.append(action)

		// If the keyboard shortcut already exist, we register it.
		if let shortcut = getShortcut(for: name) {
			register(shortcut)
		}
	}

	private static let userDefaultsPrefix = "KeyboardShortcuts_"

	private static func userDefaultsKey(for shortcutName: Name) -> String { "\(userDefaultsPrefix)\(shortcutName.rawValue)"
	}

	static func userDefaultsDidChange(name: Name) {
		// TODO: Use proper UserDefaults observation instead of this.
		NotificationCenter.default.post(name: .shortcutByNameDidChange, object: nil, userInfo: ["name": name])
	}

	static func userDefaultsSet(name: Name, shortcut: Shortcut) {
		guard let encoded = try? JSONEncoder().encode(shortcut).string else {
			return
		}

		if let oldShortcut = getShortcut(for: name) {
			unregister(oldShortcut)
		}

		register(shortcut)
		UserDefaults.standard.set(encoded, forKey: userDefaultsKey(for: name))
		userDefaultsDidChange(name: name)
	}

	static func userDefaultsRemove(name: Name) {
		guard let shortcut = getShortcut(for: name) else {
			return
		}

		UserDefaults.standard.set(false, forKey: userDefaultsKey(for: name))
		unregister(shortcut)
		userDefaultsDidChange(name: name)
	}

	static func userDefaultsContains(name: Name) -> Bool {
		UserDefaults.standard.object(forKey: userDefaultsKey(for: name)) != nil
	}
}

extension Notification.Name {
	static let shortcutByNameDidChange = Self("KeyboardShortcuts_shortcutByNameDidChange")
}
