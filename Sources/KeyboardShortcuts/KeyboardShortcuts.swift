#if os(macOS)
import Foundation

/**
Global keyboard shortcuts for your macOS app.
*/
public enum KeyboardShortcuts {
	/**
	The result of validating a keyboard shortcut.
	*/
	public enum ValidationResult: Sendable, Equatable {
		/**
		The shortcut is allowed.
		*/
		case allow

		/**
		The shortcut is disallowed.

		- Parameter reason: A message explaining why the shortcut is disallowed.
		*/
		case disallow(reason: String)

		/**
		Creates a disallow result with a localized reason.
		*/
		@available(macOS 13, *)
		public static func disallow(reason: LocalizedStringResource) -> Self {
			.disallow(reason: String(localized: reason))
		}
	}

	private static var hotKeys = [Shortcut: HotKey]()
	private static var disabledNames = Set<Name>()

	private static var keyDownHandlers = [Name: [() -> Void]]()
	private static var keyUpHandlers = [Name: [() -> Void]]()

	private static var streamKeyDownHandlers = [Name: [UUID: () -> Void]]()
	private static var streamKeyUpHandlers = [Name: [UUID: () -> Void]]()
	private static var streamShortcutKeyDownHandlers = [Shortcut: [UUID: () -> Void]]()
	private static var streamShortcutKeyUpHandlers = [Shortcut: [UUID: () -> Void]]()

	private static var isInitialized = false

	/**
	When `true`, event handlers will not be called for registered keyboard shortcuts.
	*/
	static var isPaused = false

	/**
	Enable/disable monitoring of all keyboard shortcuts.

	The default is `true`.
	*/
	public static var isEnabled = true {
		didSet {
			guard isEnabled != oldValue else {
				return
			}

			updateHotKeyMode()
		}
	}

	/**
	All shortcut names that currently have a stored value in `UserDefaults`.

	This includes names whose shortcut was set by the user or via an `initial:` parameter on ``Name/init(_:initial:)``. Names that were never stored will not appear. The returned `Name` instances only carry the `rawValue`, not the `initialShortcut`.

	Useful for dynamic shortcut management, for example, removing deprecated shortcuts:

	```swift
	let activeNames: Set<String> = ["newAction", "anotherAction"]

	for name in KeyboardShortcuts.storedNames where !activeNames.contains(name.rawValue) {
		KeyboardShortcuts.setShortcut(nil, for: name)
	}
	```
	*/
	public static var storedNames: Set<Name> {
		UserDefaults.standard.dictionaryRepresentation()
			.compactMap { key, _ in
				guard key.hasPrefix(userDefaultsPrefix) else {
					return nil
				}

				let rawValue = key.replacingPrefix(userDefaultsPrefix, with: "")
				return .init(rawValueWithoutInitialization: rawValue)
			}
			.toSet()
	}

	private static func updateHotKeyMode() {
		HotKeyCenter.shared.setEnabled(isEnabled)
	}

	private static var namesWithKeyHandlers: Set<Name> {
		Set(keyDownHandlers.keys).union(keyUpHandlers.keys)
	}

	private static var namesWithAllHandlers: Set<Name> {
		namesWithKeyHandlers
			.union(streamKeyDownHandlers.keys)
			.union(streamKeyUpHandlers.keys)
	}

	private static func hasHandlers<Handlers: Collection>(for name: Name, in handlers: [Name: Handlers]) -> Bool {
		handlers[name]?.isEmpty == false
	}

	private static func hasHandlers(for name: Name) -> Bool {
		hasHandlers(for: name, in: keyDownHandlers)
			|| hasHandlers(for: name, in: keyUpHandlers)
			|| hasHandlers(for: name, in: streamKeyDownHandlers)
			|| hasHandlers(for: name, in: streamKeyUpHandlers)
	}

	private static func hasHandlers<Handlers: Collection>(for shortcut: Shortcut, in handlers: [Shortcut: Handlers]) -> Bool {
		handlers[shortcut]?.isEmpty == false
	}

	/**
	Returns whether a hard-coded shortcut has active stream handlers.
	*/
	private static func hasHardCodedStreamHandlers(for shortcut: Shortcut) -> Bool {
		hasHandlers(for: shortcut, in: streamShortcutKeyDownHandlers)
			|| hasHandlers(for: shortcut, in: streamShortcutKeyUpHandlers)
	}

	private static func hasActiveHandlers(for name: Name) -> Bool {
		guard !disabledNames.contains(name) else {
			return false
		}

		return hasHandlers(for: name)
	}

	private static func hasActiveStreamHandlers(for name: Name) -> Bool {
		guard !disabledNames.contains(name) else {
			return false
		}

		return hasHandlers(for: name, in: streamKeyDownHandlers)
			|| hasHandlers(for: name, in: streamKeyUpHandlers)
	}

	private static func isShortcutActive(_ shortcut: Shortcut, excluding nameToExclude: Name? = nil) -> Bool {
		let hasActiveNamedHandlers = namesWithAllHandlers.contains { name in
			if let nameToExclude, name == nameToExclude {
				return false
			}

			guard hasActiveHandlers(for: name) else {
				return false
			}

			return getShortcut(for: name) == shortcut
		}

		guard !hasActiveNamedHandlers else {
			return true
		}

		return hasHardCodedStreamHandlers(for: shortcut)
	}

	/**
	Removes a stream handler from a dictionary and prunes the key when the last handler is removed.
	*/
	private static func removeStreamHandlerEntry<Key: Hashable>(
		_ id: UUID,
		for key: Key,
		in handlers: inout [Key: [UUID: () -> Void]]
	) {
		handlers[key]?[id] = nil

		if handlers[key]?.isEmpty == true {
			handlers[key] = nil
		}
	}

	private static func registerIfNeeded(for shortcut: Shortcut) {
		guard hotKeys[shortcut] == nil else {
			return
		}

		let hotKey = HotKey(
			carbonKeyCode: shortcut.carbonKeyCode,
			carbonModifiers: shortcut.carbonModifiers,
			onKeyDown: { [shortcut] in handleKeyEvent(.keyDown, for: shortcut) },
			onKeyUp: { [shortcut] in handleKeyEvent(.keyUp, for: shortcut) }
		)

		hotKey?.onRegistrationFailed = { [shortcut, weak hotKey] in
			guard
				let hotKey,
				hotKeys[shortcut] === hotKey
			else {
				return
			}

			hotKeys[shortcut] = nil
		}

		hotKeys[shortcut] = hotKey
	}

	/**
	Register the shortcut for the given name if it has a shortcut and isn't already registered.
	*/
	private static func registerIfNeeded(for name: Name) {
		guard hasActiveHandlers(for: name) else {
			return
		}

		guard let shortcut = getShortcut(for: name) else {
			return
		}

		registerIfNeeded(for: shortcut)
	}

	private static func unregister(_ shortcut: Shortcut) {
		hotKeys[shortcut] = nil // HotKey.deinit handles Carbon unregistration
	}

	/**
	Unregister the shortcut for the given name if no other names use it.
	*/
	private static func unregisterIfNeeded(for name: Name, excludingCurrentName: Bool = true) {
		guard let shortcut = getShortcut(for: name) else {
			return
		}

		let excludedName = excludingCurrentName ? name : nil

		guard !isShortcutActive(shortcut, excluding: excludedName) else {
			return
		}

		unregister(shortcut)
	}

	private static func unregisterIfNeeded(for shortcut: Shortcut) {
		guard !isShortcutActive(shortcut) else {
			return
		}

		unregister(shortcut)
	}

	private static func unregisterAll() {
		hotKeys.removeAll() // HotKey.deinit handles Carbon unregistration
	}

	static func initialize() {
		guard !isInitialized else {
			return
		}

		_ = HotKeyCenter.shared
		isInitialized = true
	}

	/**
	Remove all handlers receiving keyboard shortcuts events.

	This can be used to reset the handlers before re-creating them to avoid having multiple handlers for the same shortcut.

	- Note: This method does not affect listeners using ``events(for:)``.
	*/
	public static func removeAllHandlers() {
		// Collect shortcuts that might need unregistering
		let shortcutsToCheck = namesWithKeyHandlers.compactMap { getShortcut(for: $0) }.toSet()

		keyDownHandlers = [:]
		keyUpHandlers = [:]

		// Unregister shortcuts that no longer have any handlers
		for shortcut in shortcutsToCheck where !isShortcutActive(shortcut) {
			unregister(shortcut)
		}
	}

	/**
	Remove the keyboard shortcut handler for the given name.

	This can be used to reset the handler before re-creating it to avoid having multiple handlers for the same shortcut.

	- Parameter name: The name of the keyboard shortcut to remove handlers for.

	- Note: This method does not affect listeners using ``events(for:)``.
	*/
	public static func removeHandler(for name: Name) {
		keyDownHandlers[name] = nil
		keyUpHandlers[name] = nil

		guard !hasActiveStreamHandlers(for: name) else {
			return
		}

		unregisterIfNeeded(for: name)
	}

	/**
	Returns whether the keyboard shortcut for the given name is enabled.

	This checks if the shortcut is registered and will trigger handlers. It respects the global ``isEnabled``.

	```swift
	let isEnabled = KeyboardShortcuts.isEnabled(for: .toggleUnicornMode)
	```

	- Tip: Use ``disable(_:)-(Name...)`` and ``enable(_:)-(Name...)`` to change the status.
	*/
	public static func isEnabled(for name: Name) -> Bool {
		guard
			isEnabled,
			hasActiveHandlers(for: name),
			let shortcut = getShortcut(for: name),
			hotKeys[shortcut] != nil
		else {
			return false
		}

		return true
	}

	/**
	Disable the keyboard shortcut for one or more names.
	*/
	public static func disable(_ names: [Name]) {
		for name in names {
			disabledNames.insert(name)
			unregisterIfNeeded(for: name)
		}
	}

	/**
	Disable the keyboard shortcut for one or more names.
	*/
	public static func disable(_ names: Name...) {
		disable(names)
	}

	/**
	Enable the keyboard shortcut for one or more names.
	*/
	public static func enable(_ names: [Name]) {
		for name in names {
			disabledNames.remove(name)
			registerIfNeeded(for: name)
		}
	}

	/**
	Enable the keyboard shortcut for one or more names.
	*/
	public static func enable(_ names: Name...) {
		enable(names)
	}

	/**
	Reset the keyboard shortcut for one or more names.

	If the `Name` has a default shortcut, it will reset to that.

	- Note: This overload exists as Swift doesn't support splatting.

	```swift
	import SwiftUI
	import KeyboardShortcuts

	struct SettingsScreen: View {
		var body: some View {
			VStack {
				// …
				Button("Reset") {
					KeyboardShortcuts.reset(.toggleUnicornMode)
				}
			}
		}
	}
	```
	*/
	public static func reset(_ names: [Name]) {
		for name in names {
			setShortcut(name.initialShortcut, for: name)
		}
	}

	/**
	Reset the keyboard shortcut for one or more names.

	If the `Name` has a default shortcut, it will reset to that.

	```swift
	import SwiftUI
	import KeyboardShortcuts

	struct SettingsScreen: View {
		var body: some View {
			VStack {
				// …
				Button("Reset") {
					KeyboardShortcuts.reset(.toggleUnicornMode)
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
	Reset the keyboard shortcut for all the names.

	Unlike `reset(…)`, this resets all the shortcuts to `nil`, not the `defaultValue`.

	```swift
	import SwiftUI
	import KeyboardShortcuts

	struct SettingsScreen: View {
		var body: some View {
			VStack {
				// …
				Button("Reset All") {
					KeyboardShortcuts.resetAll()
				}
			}
		}
	}
	```
	*/
	public static func resetAll() {
		for name in storedNames {
			setShortcut(nil, for: name)
		}
	}

	/**
	Set the keyboard shortcut for a name.

	Setting it to `nil` removes the shortcut, even if the `Name` has a default shortcut defined. Use `.reset()` if you want it to respect the default shortcut.

	You would usually not need this as the user would be the one setting the shortcut in a settings user-interface, but it can be useful when, for example, migrating from a different keyboard shortcuts package.
	*/
	public static func setShortcut(_ shortcut: Shortcut?, for name: Name) {
		if let shortcut {
			userDefaultsSet(name: name, shortcut: shortcut)
			return
		}

		if name.initialShortcut != nil {
			userDefaultsDisable(name: name)
		} else {
			userDefaultsRemove(name: name)
		}
	}

	/**
	Get the keyboard shortcut for a name.
	*/
	public static func getShortcut(for name: Name) -> Shortcut? {
		if case .shortcut(let shortcut) = storedShortcut(for: name) {
			return shortcut
		}

		return nil
	}

	private static func handleKeyEvent(_ eventType: EventType, for shortcut: Shortcut) {
		guard !isPaused else {
			return
		}

		let handlers = eventType == .keyDown ? keyDownHandlers : keyUpHandlers
		let streamHandlers = eventType == .keyDown ? streamKeyDownHandlers : streamKeyUpHandlers
		let streamShortcutHandlers = eventType == .keyDown ? streamShortcutKeyDownHandlers : streamShortcutKeyUpHandlers

		invokeHandlers(for: shortcut, in: handlers) { callbacks in
			for callback in callbacks {
				callback()
			}
		}

		invokeHandlers(for: shortcut, in: streamHandlers) { callbacks in
			for callback in callbacks.values {
				callback()
			}
		}

		if let callbacks = streamShortcutHandlers[shortcut] {
			for callback in callbacks.values {
				callback()
			}
		}
	}

	private static func invokeHandlers<Handlers>(
		for shortcut: Shortcut,
		in handlers: [Name: Handlers],
		_ handleCallbacks: (Handlers) -> Void
	) {
		for (name, callbacks) in handlers {
			guard
				getShortcut(for: name) == shortcut,
				!disabledNames.contains(name)
			else {
				continue
			}

			handleCallbacks(callbacks)
		}
	}

	/**
	Listen to the keyboard shortcut with the given name being pressed.

	You can register multiple listeners.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	- Important: This will be deprecated in the future. Prefer ``events(for:)`` for new code.

	```swift
	import AppKit
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
		keyDownHandlers[name, default: []].append(action)
		registerIfNeeded(for: name)
	}

	/**
	Listen to the keyboard shortcut with the given name being pressed.

	You can register multiple listeners.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	- Important: This will be deprecated in the future. Prefer ``events(for:)`` for new code.

	```swift
	import AppKit
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
		keyUpHandlers[name, default: []].append(action)
		registerIfNeeded(for: name)
	}

	nonisolated private static let userDefaultsPrefix = "KeyboardShortcuts_"

	nonisolated static func userDefaultsKey(forRawValue rawValue: String) -> String {
		"\(userDefaultsPrefix)\(rawValue)"
	}

	nonisolated static func encodedShortcutForStorage(_ shortcut: Shortcut) -> String? {
		try? JSONEncoder().encode(shortcut).toString
	}

	nonisolated static func setInitialShortcutIfNeeded(
		_ shortcut: Shortcut,
		forRawValue rawValue: String
	) {
		let key = userDefaultsKey(forRawValue: rawValue)

		guard
			UserDefaults.standard.object(forKey: key) == nil,
			let encodedShortcut = encodedShortcutForStorage(shortcut)
		else {
			return
		}

		UserDefaults.standard.set(encodedShortcut, forKey: key)
	}

	private static func userDefaultsKey(for shortcutName: Name) -> String {
		userDefaultsKey(forRawValue: shortcutName.rawValue)
	}

	private enum StoredShortcut {
		case shortcut(Shortcut)
		case disabled
		case missing
	}

	private static func userDefaultsValue(for name: Name) -> Any? {
		UserDefaults.standard.object(forKey: userDefaultsKey(for: name))
	}

	private static func storedShortcut(for name: Name) -> StoredShortcut {
		guard let storedValue = userDefaultsValue(for: name) else {
			return .missing
		}

		if let isEnabled = storedValue as? Bool, !isEnabled {
			return .disabled
		}

		guard
			let shortcutString = storedValue as? String,
			let data = shortcutString.data(using: .utf8),
			let shortcut = try? JSONDecoder().decode(Shortcut.self, from: data)
		else {
			return .missing
		}

		return .shortcut(shortcut)
	}

	private static func isShortcutDisabled(for name: Name) -> Bool {
		userDefaultsValue(for: name) as? Bool == false
	}

	static func userDefaultsDidChange(name: Name) {
		// TODO: Use proper UserDefaults observation instead of this.
		NotificationCenter.default.post(name: .shortcutByNameDidChange, object: nil, userInfo: [NotificationUserInfoKey.name: name])
	}

	private static func updateStoredShortcut(for name: Name, update: () -> Void) {
		unregisterIfNeeded(for: name)
		update()
		registerIfNeeded(for: name)
		userDefaultsDidChange(name: name)
	}

	static func userDefaultsSet(name: Name, shortcut: Shortcut) {
		guard let encoded = encodedShortcutForStorage(shortcut) else {
			return
		}

		updateStoredShortcut(for: name) {
			UserDefaults.standard.set(encoded, forKey: userDefaultsKey(for: name))
		}
	}

	static func userDefaultsDisable(name: Name) {
		guard !isShortcutDisabled(for: name) else {
			return
		}

		updateStoredShortcut(for: name) {
			UserDefaults.standard.set(false, forKey: userDefaultsKey(for: name))
		}
	}

	static func userDefaultsRemove(name: Name) {
		guard userDefaultsValue(for: name) != nil else {
			return
		}

		updateStoredShortcut(for: name) {
			UserDefaults.standard.removeObject(forKey: userDefaultsKey(for: name))
		}
	}

	static func userDefaultsContains(name: Name) -> Bool {
		userDefaultsValue(for: name) != nil
	}
}

extension KeyboardShortcuts {
	nonisolated public enum EventType: Sendable, Equatable {
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
	public static func events(for name: Name) -> AsyncStream<KeyboardShortcuts.EventType> {
		AsyncStream { continuation in
			let id = UUID()

			streamKeyDownHandlers[name, default: [:]][id] = {
				continuation.yield(.keyDown)
			}

			streamKeyUpHandlers[name, default: [:]][id] = {
				continuation.yield(.keyUp)
			}

			registerIfNeeded(for: name)

			continuation.onTermination = { _ in
				Task { @MainActor in
					removeStreamHandlerEntry(id, for: name, in: &streamKeyDownHandlers)
					removeStreamHandlerEntry(id, for: name, in: &streamKeyUpHandlers)

					unregisterIfNeeded(for: name, excludingCurrentName: false)
				}
			}
		}
	}

	/**
	Listen to hard-coded keyboard shortcut events.

	Use this for shortcuts you define in code instead of storing in ``Name``.

	Ending the async sequence will stop the listener.

	```swift
	import KeyboardShortcuts

	let shortcut = KeyboardShortcuts.Shortcut(.a, modifiers: [.command])

	Task {
		for await eventType in KeyboardShortcuts.events(for: shortcut) where eventType == .keyUp {
			// Do something.
		}
	}
	```

	- Important: In apps distributed to users, prefer user-customizable shortcuts when possible.
	- Note: This method is not affected by `.removeAllHandlers()`.
	*/
	public static func events(for shortcut: Shortcut) -> AsyncStream<KeyboardShortcuts.EventType> {
		AsyncStream { continuation in
			let id = UUID()

			streamShortcutKeyDownHandlers[shortcut, default: [:]][id] = {
				continuation.yield(.keyDown)
			}

			streamShortcutKeyUpHandlers[shortcut, default: [:]][id] = {
				continuation.yield(.keyUp)
			}

			registerIfNeeded(for: shortcut)

			continuation.onTermination = { _ in
				Task { @MainActor in
					removeStreamHandlerEntry(id, for: shortcut, in: &streamShortcutKeyDownHandlers)
					removeStreamHandlerEntry(id, for: shortcut, in: &streamShortcutKeyUpHandlers)

					unregisterIfNeeded(for: shortcut)
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
	public static func events(_ type: EventType, for name: Name) -> AsyncFilterSequence<AsyncStream<EventType>> {
		events(for: name).filter { $0 == type }
	}
}

extension Notification.Name {
	static let shortcutByNameDidChange = Self("KeyboardShortcuts_shortcutByNameDidChange")
}
#endif
