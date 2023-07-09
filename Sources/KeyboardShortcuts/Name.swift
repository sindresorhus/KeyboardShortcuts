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
		The keyboard shortcut assigned to the name.
		*/
		public var shortcut: Shortcut? {
			get { KeyboardShortcuts.getShortcut(for: self) }
			nonmutating set {
				KeyboardShortcuts.setShortcut(newValue, for: self)
			}
		}

		/**
		- Parameter name: Name of the shortcut.
		- Parameter default: Optional default key combination. Do not set this unless it's essential. Users find it annoying when random apps steal their existing keyboard shortcuts. It's generally better to show a welcome screen on the first app launch that lets the user set the shortcut.
		*/
		public init(_ name: String, default initialShortcut: Shortcut? = nil) {
			self.rawValue = name
			self.defaultShortcut = initialShortcut

			if
				let initialShortcut,
				!userDefaultsContains(name: self)
			{
				setShortcut(initialShortcut, for: self)
			}

			KeyboardShortcuts.initialize()
		}
	}
}

extension KeyboardShortcuts.Name: RawRepresentable {
	/// :nodoc:
	public init?(rawValue: String) {
		self.init(rawValue)
	}
}
