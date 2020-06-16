extension KeyboardShortcuts {
	/**
	The strongly-typed name of the keyboard shortcut.

	After registering it, you can use it in, for example, `KeyboardShortcut.Recorder` and `KeyboardShortcut.onKeyUp()`.

	```
	import KeyboardShortcuts

	extension KeyboardShortcuts.Name {
		static let toggleUnicornMode = Name("toggleUnicornMode")
	}
	```
	*/
	public struct Name: Hashable {
		// These are to allow using the types without the namespace
		// `extension KeyboardShortcuts.Name { static let x = Name("x") }`.
		/// :nodoc:
		public typealias Name = KeyboardShortcuts.Name
		/// :nodoc:
		public typealias Shortcut = KeyboardShortcuts.Shortcut

		public let rawValue: String

		/**
		Creates a strongly-typed name of the keyboard shortcut.
		- Parameter name: name of shortcut
		- Parameter default: optional default key combination for the shortcut
		*/
		public init(_ name: String, default defaultShortcut: Shortcut? = nil) {
			self.rawValue = name

			if let defaultShortcut = defaultShortcut, userDefaultsGet(name: self) == nil {
				userDefaultsSet(name: self, shortcut: defaultShortcut)
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
