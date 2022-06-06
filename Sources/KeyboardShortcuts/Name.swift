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
	public struct Name: Hashable {
		// This makes it possible to use `Shortcut` without the namespace.
		/// :nodoc:
		public typealias Shortcut = KeyboardShortcuts.Shortcut

		public let rawValue: String
		public let defaultShortcut: Shortcut?

		/**
		Get the keyboard shortcut assigned to the name.
		*/
		public var shortcut: Shortcut? { KeyboardShortcuts.getShortcut(for: self) }

		/**
		- Parameter name: Name of the shortcut.
		- Parameter default: Optional default key combination. Do not set this unless it's essential. Users find it annoying when random apps steal their existing keyboard shortcuts. It's generally better to show a welcome screen on the first app launch that lets the user set the shortcut.
		*/
		public init(_ name: String, default defaultShortcut: Shortcut? = nil) {
			self.rawValue = name
			self.defaultShortcut = defaultShortcut

			if
				let defaultShortcut = defaultShortcut,
				!userDefaultsContains(name: self)
			{
				setShortcut(defaultShortcut, for: self)
			}
		}
	}
}

extension KeyboardShortcuts.Name: RawRepresentable {
	/// :nodoc:
	public init?(rawValue: String) {
		self.init(rawValue)
	}
}
