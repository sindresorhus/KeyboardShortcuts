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
		// This is to allow `extension KeyboardShortcuts.Name { static let x = Name("x") }`.
		/// :nodoc:
		public typealias Name = KeyboardShortcuts.Name

		public let rawValue: String

		public init(_ name: String) {
			self.rawValue = name
		}
	}
}

extension KeyboardShortcuts.Name: RawRepresentable {
	/// :nodoc:
	public init?(rawValue: String) {
		self.init(rawValue)
	}
}
