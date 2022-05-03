import Cocoa

/**
Global keyboard shortcuts for your macOS app.
*/
public enum KeyboardShortcuts {
	private static var registeredShortcuts = Set<Shortcut>()

	private static var legacyKeyDownHandlers = [Name: [() -> Void]]()
	private static var legacyKeyUpHandlers = [Name: [() -> Void]]()

	private static var streamKeyDownHandlers = [Name: [UUID: () -> Void]]()
	private static var streamKeyUpHandlers = [Name: [UUID: () -> Void]]()

	private static var shortcutsForLegacyHandlers: Set<Shortcut> {
		let shortcuts = [legacyKeyDownHandlers.keys, legacyKeyUpHandlers.keys]
			.flatMap { $0 }
			.compactMap(\.shortcut)

		return Set(shortcuts)
	}

	private static var shortcutsForStreamHandlers: Set<Shortcut> {
		let shortcuts = [streamKeyDownHandlers.keys, streamKeyUpHandlers.keys]
			.flatMap { $0 }
			.compactMap(\.shortcut)

		return Set(shortcuts)
	}

	private static var shortcutsForHandlers: Set<Shortcut> {
		shortcutsForLegacyHandlers.union(shortcutsForStreamHandlers)
	}

	/**
	When `true`, event handlers will not be called for registered keyboard shortcuts.
	*/
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

	/**
	Register the shortcut for the given name if it has a shortcut.
	*/
	private static func registerShortcutIfNeeded(for name: Name) {
		guard let shortcut = getShortcut(for: name) else {
			return
		}

		register(shortcut)
	}

	private static func unregister(_ shortcut: Shortcut) {
		CarbonKeyboardShortcuts.unregister(shortcut)
		registeredShortcuts.remove(shortcut)
	}

	/**
	Unregister the given shortcut if it has no handlers.
	*/
	private static func unregisterIfNeeded(_ shortcut: Shortcut) {
		guard !shortcutsForHandlers.contains(shortcut) else {
			return
		}

		unregister(shortcut)
	}

	/**
	Unregister the shortcut for the given name if it has no handlers.
	*/
	private static func unregisterShortcutIfNeeded(for name: Name) {
		guard let shortcut = name.shortcut else {
			return
		}

		unregisterIfNeeded(shortcut)
	}

	private static func unregisterAll() {
		CarbonKeyboardShortcuts.unregisterAll()
		registeredShortcuts.removeAll()

		// TODO: Should remove user defaults too.
	}

	/**
	Remove all handlers receiving keyboard shortcuts events.

	This can be used to reset the handlers before re-creating them to avoid having multiple handlers for the same shortcut.

	- Note: This method does not affect listeners using `.on()`.
	*/
	public static func removeAllHandlers() {
		let shortcutsToUnregister = shortcutsForLegacyHandlers.subtracting(shortcutsForStreamHandlers)

		for shortcut in shortcutsToUnregister {
			unregister(shortcut)
		}

		legacyKeyDownHandlers = [:]
		legacyKeyUpHandlers = [:]
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

	```swift
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

	```swift
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

		for (name, handlers) in legacyKeyDownHandlers {
			guard getShortcut(for: name) == shortcut else {
				continue
			}

			for handler in handlers {
				handler()
			}
		}

		for (name, handlers) in streamKeyDownHandlers {
			guard getShortcut(for: name) == shortcut else {
				continue
			}

			for handler in handlers.values {
				handler()
			}
		}
	}

	private static func handleOnKeyUp(_ shortcut: Shortcut) {
		guard !isPaused else {
			return
		}

		for (name, handlers) in legacyKeyUpHandlers {
			guard getShortcut(for: name) == shortcut else {
				continue
			}

			for handler in handlers {
				handler()
			}
		}

		for (name, handlers) in streamKeyUpHandlers {
			guard getShortcut(for: name) == shortcut else {
				continue
			}

			for handler in handlers.values {
				handler()
			}
		}
	}

	/**
	Listen to the keyboard shortcut with the given name being pressed.

	You can register multiple listeners.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	```swift
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
	public static func onKeyDown(for name: Name, action: @escaping () -> Void) {
		legacyKeyDownHandlers[name, default: []].append(action)
		registerShortcutIfNeeded(for: name)
	}

	/**
	Listen to the keyboard shortcut with the given name being pressed.

	You can register multiple listeners.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	```swift
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
	public static func onKeyUp(for name: Name, action: @escaping () -> Void) {
		legacyKeyUpHandlers[name, default: []].append(action)
		registerShortcutIfNeeded(for: name)
	}

	private static let userDefaultsPrefix = "KeyboardShortcuts_"

	private static func userDefaultsKey(for shortcutName: Name) -> String { "\(userDefaultsPrefix)\(shortcutName.rawValue)"
	}

	static func userDefaultsDidChange(name: Name) {
		// TODO: Use proper UserDefaults observation instead of this.
		NotificationCenter.default.post(name: .shortcutByNameDidChange, object: nil, userInfo: ["name": name])
	}

	static func userDefaultsSet(name: Name, shortcut: Shortcut) {
		guard let encoded = try? JSONEncoder().encode(shortcut).toString else {
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

extension KeyboardShortcuts {
	@available(macOS 10.15, *)
	public enum EventType {
		case keyDown
		case keyUp
	}

	/**
	Listen to the keyboard shortcut with the given name being pressed.

	You can register multiple listeners.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	Ending the async sequence will stop the listener. For example, in the below example, the listener will stop when the view disappears.

	```swift
	import SwiftUI
	import KeyboardShortcuts

	struct ContentView: View {
		@State private var isUnicornMode = false

		var body: some View {
			Text(isUnicornMode ? "🦄" : "🐴")
				.task {
					for await event in KeyboardShortcuts.events(for: .toggleUnicornMode) where event == .keyUp {
						isUnicornMode.toggle()
					}
				}
		}
	}
	```

	- Note: This method is not affected by `.removeAllHandlers()`.
	*/
	@available(macOS 10.15, *)
	public static func events(for name: Name) -> AsyncStream<KeyboardShortcuts.EventType> {
		AsyncStream { continuation in
			let id = UUID()

			DispatchQueue.main.async {
				streamKeyDownHandlers[name, default: [:]][id] = {
					continuation.yield(.keyDown)
				}

				streamKeyUpHandlers[name, default: [:]][id] = {
					continuation.yield(.keyUp)
				}

				registerShortcutIfNeeded(for: name)
			}

			continuation.onTermination = { _ in
				DispatchQueue.main.async {
					streamKeyDownHandlers[name]?[id] = nil
					streamKeyUpHandlers[name]?[id] = nil

					unregisterShortcutIfNeeded(for: name)
				}
			}
		}
	}

	/**
	Listen to keyboard shortcut events with the given name and type.

	You can register multiple listeners.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	Ending the async sequence will stop the listener. For example, in the below example, the listener will stop when the view disappears.

	```swift
	import SwiftUI
	import KeyboardShortcuts

	struct ContentView: View {
		@State private var isUnicornMode = false

		var body: some View {
			Text(isUnicornMode ? "🦄" : "🐴")
				.task {
					for await event in KeyboardShortcuts.events(for: .toggleUnicornMode) where event == .keyUp {
						isUnicornMode.toggle()
					}
				}
		}
	}
	```

	- Note: This method is not affected by `.removeAllHandlers()`.
	*/
	@available(macOS 10.15, *)
	public static func events(_ type: EventType, for name: Name) -> AsyncFilterSequence<AsyncStream<EventType>> {
		events(for: name).filter { $0 == type }
	}

	@available(macOS 10.15, *)
	@available(*, deprecated, renamed: "events(_:for:)")
	public static func on(_ type: EventType, for name: Name) -> AsyncStream<Void> {
		AsyncStream { continuation in
			let id = UUID()

			switch type {
			case .keyDown:
				streamKeyDownHandlers[name, default: [:]][id] = {
					continuation.yield()
				}
			case .keyUp:
				streamKeyUpHandlers[name, default: [:]][id] = {
					continuation.yield()
				}
			}

			registerShortcutIfNeeded(for: name)

			continuation.onTermination = { _ in
				switch type {
				case .keyDown:
					streamKeyDownHandlers[name]?[id] = nil
				case .keyUp:
					streamKeyUpHandlers[name]?[id] = nil
				}

				unregisterShortcutIfNeeded(for: name)
			}
		}
	}
}

extension Notification.Name {
	static let shortcutByNameDidChange = Self("KeyboardShortcuts_shortcutByNameDidChange")
}
