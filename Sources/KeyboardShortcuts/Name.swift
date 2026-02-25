#if os(macOS)
extension KeyboardShortcuts {
	/**
	The strongly-typed name of the keyboard shortcut.

	After registering it, you can use it in, for example, `KeyboardShortcut.Recorder` and `KeyboardShortcut.onKeyUp()`.

	```swift
	import KeyboardShortcuts

	extension KeyboardShortcuts.Name {
		static let toggleUnicornMode = Self("toggleUnicornMode")
	}
	```
	*/
	nonisolated public struct Name: Hashable, Sendable {
		// This makes it possible to use `Shortcut` without the namespace.
		@_documentation(visibility: private)
		public typealias Shortcut = KeyboardShortcuts.Shortcut

		public let rawValue: String
		public let initialShortcut: Shortcut?

		@available(*, deprecated, renamed: "initialShortcut")
		public var defaultShortcut: Shortcut? { initialShortcut }

		/**
		- Parameter name: Name of the shortcut.
		- Parameter initialShortcut: Optional initial key combination. Do not set this unless it's essential. Users find it annoying when random apps steal their existing keyboard shortcuts. It's generally better to show a welcome screen on the first app launch that lets the user set the shortcut.
		- Important: The name must not contain a dot (`.`) because it is used as a key path for observation.
		*/
		nonisolated
		public init(_ name: String, initial initialShortcut: Shortcut? = nil) {
			runtimeWarn(
				KeyboardShortcuts.isValidShortcutName(name),
				"The keyboard shortcut name must not contain a dot (.)."
			)

			self.rawValue = name
			self.initialShortcut = initialShortcut

			if let initialShortcut {
				KeyboardShortcuts.setInitialShortcutIfNeeded(
					initialShortcut,
					forRawValue: name
				)
			}

			// TODO: Use `Task.immediate` when targeting macOS 26.
			Task { @MainActor in
				KeyboardShortcuts.initialize()
			}
		}

		@available(*, deprecated, renamed: "init(_:initial:)")
		nonisolated
		public init(_ name: String, `default` initialShortcut: Shortcut?) {
			self.init(name, initial: initialShortcut)
		}
	}
}

nonisolated
extension KeyboardShortcuts.Name {
	init(rawValueWithoutInitialization rawValue: String) {
		self.rawValue = rawValue
		self.initialShortcut = nil
	}
}

nonisolated
extension KeyboardShortcuts.Name: RawRepresentable {
	@_documentation(visibility: private)
	public init?(rawValue: String) {
		self.init(rawValueWithoutInitialization: rawValue)
	}
}

extension KeyboardShortcuts.Name {
	/**
	The keyboard shortcut assigned to the name.
	*/
	@MainActor
	public var shortcut: Shortcut? {
		get {
			KeyboardShortcuts.getShortcut(for: self)
		}
		nonmutating set {
			KeyboardShortcuts.setShortcut(newValue, for: self)
		}
	}
}
#endif
