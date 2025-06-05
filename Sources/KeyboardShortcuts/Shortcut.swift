#if os(macOS)
import AppKit
import Carbon.HIToolbox
import SwiftUI

extension KeyboardShortcuts {
	/**
	A keyboard shortcut.
	*/
	public struct Shortcut: Hashable, Codable, Sendable {
		/**
		Carbon modifiers are not always stored as the same number.

		For example, the system has `⌃F2` stored with the modifiers number `135168`, but if you press the keyboard shortcut, you get `4096`.
		*/
		private static func normalizeModifiers(_ carbonModifiers: Int) -> Int {
			NSEvent.ModifierFlags(carbon: carbonModifiers).carbon
		}

		/**
		The keyboard key of the shortcut.
		*/
		public var key: Key? { Key(rawValue: carbonKeyCode) }

		/**
		The modifier keys of the shortcut.
		*/
		public var modifiers: NSEvent.ModifierFlags { NSEvent.ModifierFlags(carbon: carbonModifiers) }

		/**
		Low-level represetation of the key.

		You most likely don't need this.
		*/
		public let carbonKeyCode: Int

		/**
		Low-level representation of the modifier keys.

		You most likely don't need this.
		*/
		public let carbonModifiers: Int

		/**
		Initialize from a strongly-typed key and modifiers.
		*/
		public init(_ key: Key, modifiers: NSEvent.ModifierFlags = []) {
			self.init(
				carbonKeyCode: key.rawValue,
				carbonModifiers: modifiers.carbon
			)
		}

		/**
		Initialize from a key event.
		*/
		public init?(event: NSEvent) {
			guard event.isKeyEvent else {
				return nil
			}

			self.init(
				carbonKeyCode: Int(event.keyCode),
				// Note: We could potentially support users specifying shortcuts with the Fn key, but I haven't found a reliable way to differentate when to display the Fn key and not. For example, with Fn+F1 we only want to display F1, but with Fn+V, we want to display both. I cannot just specialize it for F keys as it applies to other keys too, like Fn+arrowup.
				carbonModifiers: event.modifierFlags.subtracting(.function).carbon
			)
		}

		/**
		Initialize from a keyboard shortcut stored by `Recorder` or `RecorderCocoa`.
		*/
		public init?(name: Name) {
			guard let shortcut = getShortcut(for: name) else {
				return nil
			}

			self = shortcut
		}

		/**
		Initialize from a key code number and modifier code.

		You most likely don't need this.
		*/
		public init(carbonKeyCode: Int, carbonModifiers: Int = 0) {
			self.carbonKeyCode = carbonKeyCode
			self.carbonModifiers = Self.normalizeModifiers(carbonModifiers)
		}
	}
}

enum Constants {
	static let isSandboxed = ProcessInfo.processInfo.environment.hasKey("APP_SANDBOX_CONTAINER_ID")
}

extension KeyboardShortcuts.Shortcut {
	/**
	System-defined keyboard shortcuts.
	*/
	static var system: [Self] {
		CarbonKeyboardShortcuts.system
	}

	/**
	Check whether the keyboard shortcut is disallowed.
	*/
	public var isDisallowed: Bool {
		let osVersion = ProcessInfo.processInfo.operatingSystemVersion

		guard
			osVersion.majorVersion == 15,
			osVersion.minorVersion == 0 || osVersion.minorVersion == 1,
			Constants.isSandboxed
		else {
			return false
		}

		if !modifiers.contains(.option) {
			return false // Allowed if Option is not involved
		}

		// If Option is present, ensure there's at least one modifier other than Option and Shift
		let otherModifiers: NSEvent.ModifierFlags = [.command, .control, .function, .capsLock]
		return modifiers.isDisjoint(with: otherModifiers)
	}

	/**
	Check whether the keyboard shortcut is already taken by the system.
	*/
	public var isTakenBySystem: Bool {
		guard self != Self(.f12, modifiers: []) else {
			return false
		}

		return Self.system.contains(self)
	}
}

extension KeyboardShortcuts.Shortcut {
	/**
	Recursively finds a menu item in the given menu that has a matching key equivalent and modifier.
	*/
	@MainActor
	func menuItemWithMatchingShortcut(in menu: NSMenu) -> NSMenuItem? {
		for item in menu.items {
			var keyEquivalent = item.keyEquivalent
			var keyEquivalentModifierMask = item.keyEquivalentModifierMask

			if modifiers.contains(.shift), keyEquivalent.lowercased() != keyEquivalent {
				keyEquivalent = keyEquivalent.lowercased()
				keyEquivalentModifierMask.insert(.shift)
			}

			if
				self.nsMenuItemKeyEquivalent == keyEquivalent, // Note `nil != ""`
				self.modifiers == keyEquivalentModifierMask
			{
				return item
			}

			if
				let submenu = item.submenu,
				let menuItem = menuItemWithMatchingShortcut(in: submenu)
			{
				return menuItem
			}
		}

		return nil
	}

	/**
	Returns a menu item in the app's main menu that has a matching key equivalent and modifier.
	*/
	@MainActor
	public var takenByMainMenu: NSMenuItem? {
		guard let mainMenu = NSApp.mainMenu else {
			return nil
		}

		return menuItemWithMatchingShortcut(in: mainMenu)
	}
}

/*
An enumeration of special keys requiring specific handling when used with `RecorderCocoa`, AppKit’s `NSMenuItem`, and SwiftUI’s `.keyboardShortcut(_:modifiers:)`.  

Using an enumeration ensures all cases are exhaustively addressed in all three contexts, providing compile-time safety and reducing the risk of unhandled keys.
*/
private enum SpecialKey {
	case `return`
	case delete
	case deleteForward
	case end
	case escape
	case help
	case home
	case space
	case tab
	case pageUp
	case pageDown
	case upArrow
	case rightArrow
	case downArrow
	case leftArrow
	case f1
	case f2
	case f3
	case f4
	case f5
	case f6
	case f7
	case f8
	case f9
	case f10
	case f11
	case f12
	case f13
	case f14
	case f15
	case f16
	case f17
	case f18
	case f19
	case f20
	case keypad0
	case keypad1
	case keypad2
	case keypad3
	case keypad4
	case keypad5
	case keypad6
	case keypad7
	case keypad8
	case keypad9
	case keypadClear
	case keypadDecimal
	case keypadDivide
	case keypadEnter
	case keypadEquals
	case keypadMinus
	case keypadMultiply
	case keypadPlus
}

private let keyToSpecialKeyMapping: [KeyboardShortcuts.Key: SpecialKey] = [
	.return: .return,
	.delete: .delete,
	.deleteForward: .deleteForward,
	.end: .end,
	.escape: .escape,
	.help: .help,
	.home: .home,
	.space: .space,
	.tab: .tab,
	.pageUp: .pageUp,
	.pageDown: .pageDown,
	.upArrow: .upArrow,
	.rightArrow: .rightArrow,
	.downArrow: .downArrow,
	.leftArrow: .leftArrow,
	.f1: .f1,
	.f2: .f2,
	.f3: .f3,
	.f4: .f4,
	.f5: .f5,
	.f6: .f6,
	.f7: .f7,
	.f8: .f8,
	.f9: .f9,
	.f10: .f10,
	.f11: .f11,
	.f12: .f12,
	.f13: .f13,
	.f14: .f14,
	.f15: .f15,
	.f16: .f16,
	.f17: .f17,
	.f18: .f18,
	.f19: .f19,
	.f20: .f20,
	.keypad0: .keypad0,
	.keypad1: .keypad1,
	.keypad2: .keypad2,
	.keypad3: .keypad3,
	.keypad4: .keypad4,
	.keypad5: .keypad5,
	.keypad6: .keypad6,
	.keypad7: .keypad7,
	.keypad8: .keypad8,
	.keypad9: .keypad9,
	.keypadClear: .keypadClear,
	.keypadDecimal: .keypadDecimal,
	.keypadDivide: .keypadDivide,
	.keypadEnter: .keypadEnter,
	.keypadEquals: .keypadEquals,
	.keypadMinus: .keypadMinus,
	.keypadMultiply: .keypadMultiply,
	.keypadPlus: .keypadPlus
]

extension SpecialKey {
	fileprivate var presentableDescription: String {
		switch self {
		case .return:
			"↩"
		case .delete:
			"⌫"
		case .deleteForward:
			"⌦"
		case .end:
			"↘"
		case .escape:
			"⎋"
		case .help:
			"?⃝"
		case .home:
			"↖"
		case .space:
			"space_key".localized.capitalized // This matches what macOS uses.
		case .tab:
			"⇥"
		case .pageUp:
			"⇞"
		case .pageDown:
			"⇟"
		case .upArrow:
			"↑"
		case .rightArrow:
			"→"
		case .downArrow:
			"↓"
		case .leftArrow:
			"←"
		case .f1:
			"F1"
		case .f2:
			"F2"
		case .f3:
			"F3"
		case .f4:
			"F4"
		case .f5:
			"F5"
		case .f6:
			"F6"
		case .f7:
			"F7"
		case .f8:
			"F8"
		case .f9:
			"F9"
		case .f10:
			"F10"
		case .f11:
			"F11"
		case .f12:
			"F12"
		case .f13:
			"F13"
		case .f14:
			"F14"
		case .f15:
			"F15"
		case .f16:
			"F16"
		case .f17:
			"F17"
		case .f18:
			"F18"
		case .f19:
			"F19"
		case .f20:
			"F20"

		// Representations for numeric keypad keys with   ⃣  Unicode U+20e3 'COMBINING ENCLOSING KEYCAP'
		case .keypad0:
			"0\u{20e3}"
		case .keypad1:
			"1\u{20e3}"
		case .keypad2:
			"2\u{20e3}"
		case .keypad3:
			"3\u{20e3}"
		case .keypad4:
			"4\u{20e3}"
		case .keypad5:
			"5\u{20e3}"
		case .keypad6:
			"6\u{20e3}"
		case .keypad7:
			"7\u{20e3}"
		case .keypad8:
			"8\u{20e3}"
		case .keypad9:
			"9\u{20e3}"
		// There's "⌧“ 'X In A Rectangle Box' (U+2327), "☒" 'Ballot Box with X' (U+2612), "×" 'Multiplication Sign' (U+00d7), "⨯" 'Vector or Cross Product' (U+2a2f), or a plain small x. All combined symbols appear bigger.
		case .keypadClear:
			"☒\u{20e3}" // The combined symbol appears bigger than the other combined 'keycaps'
		// TODO: Respect locale decimal separator ("." or ",")
		case .keypadDecimal:
			".\u{20e3}"
		case .keypadDivide:
			"/\u{20e3}"
		// "⏎" 'Return Symbol' (U+23CE) but "↩" 'Leftwards Arrow with Hook' (U+00d7) seems to be more common on macOS.
		case .keypadEnter:
			"↩\u{20e3}" // The combined symbol appears bigger than the other combined 'keycaps'
		case .keypadEquals:
			"=\u{20e3}"
		case .keypadMinus:
			"-\u{20e3}"
		case .keypadMultiply:
			"*\u{20e3}"
		case .keypadPlus:
			"+\u{20e3}"
		}
	}

	@available(macOS 11.0, *)
	fileprivate var swiftUIKeyEquivalent: SwiftUI.KeyEquivalent? {
		switch self {
		case .return:
			.return
		case .delete:
			.delete
		case .deleteForward:
			.deleteForward
		case .end:
			.end
		case .escape:
			.escape
		case .help:
			KeyEquivalent(unicodeScalarValue: NSHelpFunctionKey)
		case .home:
			.home
		case .space:
			.space
		case .tab:
			.tab
		case .pageUp:
			.pageUp
		case .pageDown:
			.pageDown
		case .upArrow:
			.upArrow
		case .rightArrow:
			.rightArrow
		case .downArrow:
			.downArrow
		case .leftArrow:
			.leftArrow
		case .f1:
			KeyEquivalent(unicodeScalarValue: NSF1FunctionKey)
		case .f2:
			KeyEquivalent(unicodeScalarValue: NSF2FunctionKey)
		case .f3:
			KeyEquivalent(unicodeScalarValue: NSF3FunctionKey)
		case .f4:
			KeyEquivalent(unicodeScalarValue: NSF4FunctionKey)
		case .f5:
			KeyEquivalent(unicodeScalarValue: NSF5FunctionKey)
		case .f6:
			KeyEquivalent(unicodeScalarValue: NSF6FunctionKey)
		case .f7:
			KeyEquivalent(unicodeScalarValue: NSF7FunctionKey)
		case .f8:
			KeyEquivalent(unicodeScalarValue: NSF8FunctionKey)
		case .f9:
			KeyEquivalent(unicodeScalarValue: NSF9FunctionKey)
		case .f10:
			KeyEquivalent(unicodeScalarValue: NSF10FunctionKey)
		case .f11:
			KeyEquivalent(unicodeScalarValue: NSF11FunctionKey)
		case .f12:
			KeyEquivalent(unicodeScalarValue: NSF12FunctionKey)
		case .f13:
			KeyEquivalent(unicodeScalarValue: NSF13FunctionKey)
		case .f14:
			KeyEquivalent(unicodeScalarValue: NSF14FunctionKey)
		case .f15:
			KeyEquivalent(unicodeScalarValue: NSF15FunctionKey)
		case .f16:
			KeyEquivalent(unicodeScalarValue: NSF16FunctionKey)
		case .f17:
			KeyEquivalent(unicodeScalarValue: NSF17FunctionKey)
		case .f18:
			KeyEquivalent(unicodeScalarValue: NSF18FunctionKey)
		case .f19:
			KeyEquivalent(unicodeScalarValue: NSF19FunctionKey)
		case .f20:
			KeyEquivalent(unicodeScalarValue: NSF20FunctionKey)
		// Neither the " ⃣" enclosed characters (e.g. "7⃣") nor regular
		// characters with the `.numpad` modifier produce `SwiftUI` buttons that
		// will capture the only the number pad's keys (last checked: MacOS 14).
		// Return `nil` to prevent definition of incorrect shortcuts.
		case .keypad0:
			nil
		case .keypad1:
			nil
		case .keypad2:
			nil
		case .keypad3:
			nil
		case .keypad4:
			nil
		case .keypad5:
			nil
		case .keypad6:
			nil
		case .keypad7:
			nil
		case .keypad8:
			nil
		case .keypad9:
			nil
		case .keypadClear:
			nil
		case .keypadDecimal:
			nil
		case .keypadDivide:
			nil
		case .keypadEnter:
			nil
		case .keypadEquals:
			nil
		case .keypadMinus:
			nil
		case .keypadMultiply:
			nil
		case .keypadPlus:
			nil
		}
	}

	fileprivate var appKitMenuItemKeyEquivalent: Character? {
		switch self {
		case .return:
			"↩"
		case .delete:
			"⌫"
		case .deleteForward:
			"⌦"
		case .end:
			"↘"
		case .escape:
			"⎋"
		case .help:
			"?⃝"
		case .home:
			"↖"
		case .space:
			"\u{0020}"
		case .tab:
			"⇥"
		case .pageUp:
			"⇞"
		case .pageDown:
			"⇟"
		case .upArrow:
			"↑"
		case .rightArrow:
			"→"
		case .downArrow:
			"↓"
		case .leftArrow:
			"←"
		case .f1:
			Character(unicodeScalarValue: NSF1FunctionKey)
		case .f2:
			Character(unicodeScalarValue: NSF2FunctionKey)
		case .f3:
			Character(unicodeScalarValue: NSF3FunctionKey)
		case .f4:
			Character(unicodeScalarValue: NSF4FunctionKey)
		case .f5:
			Character(unicodeScalarValue: NSF5FunctionKey)
		case .f6:
			Character(unicodeScalarValue: NSF6FunctionKey)
		case .f7:
			Character(unicodeScalarValue: NSF7FunctionKey)
		case .f8:
			Character(unicodeScalarValue: NSF8FunctionKey)
		case .f9:
			Character(unicodeScalarValue: NSF9FunctionKey)
		case .f10:
			Character(unicodeScalarValue: NSF10FunctionKey)
		case .f11:
			Character(unicodeScalarValue: NSF11FunctionKey)
		case .f12:
			Character(unicodeScalarValue: NSF12FunctionKey)
		case .f13:
			Character(unicodeScalarValue: NSF13FunctionKey)
		case .f14:
			Character(unicodeScalarValue: NSF14FunctionKey)
		case .f15:
			Character(unicodeScalarValue: NSF15FunctionKey)
		case .f16:
			Character(unicodeScalarValue: NSF16FunctionKey)
		case .f17:
			Character(unicodeScalarValue: NSF17FunctionKey)
		case .f18:
			Character(unicodeScalarValue: NSF18FunctionKey)
		case .f19:
			Character(unicodeScalarValue: NSF19FunctionKey)
		case .f20:
			Character(unicodeScalarValue: NSF20FunctionKey)
		// Neither the " ⃣" enclosed characters (e.g. "7⃣") nor regular
		// characters with the `.numericPad` modifier produce a `MenuItem` that
		// will capture the only the number pad's keys (last checked: MacOS 14).
		// Return `nil` to prevent definition of incorrect shortcuts.
		case .keypad0:
			nil
		case .keypad1:
			nil
		case .keypad2:
			nil
		case .keypad3:
			nil
		case .keypad4:
			nil
		case .keypad5:
			nil
		case .keypad6:
			nil
		case .keypad7:
			nil
		case .keypad8:
			nil
		case .keypad9:
			nil
		case .keypadClear:
			nil
		case .keypadDecimal:
			nil
		case .keypadDivide:
			nil
		case .keypadEnter:
			nil
		case .keypadEquals:
			nil
		case .keypadMinus:
			nil
		case .keypadMultiply:
			nil
		case .keypadPlus:
			nil
		}
	}
}

extension KeyboardShortcuts.Shortcut {
	@MainActor // `TISGetInputSourceProperty` crashes if called on a non-main thread.
	fileprivate func keyToCharacter() -> Character? {
		guard
			let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
			let layoutDataPointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
		else {
			return nil
		}

		guard key.flatMap({ keyToSpecialKeyMapping[$0] }) == nil else {
			assertionFailure("Special keys should get special treatment and should not be translated using keyToCharacter()")
			return nil
		}

		let layoutData = unsafeBitCast(layoutDataPointer, to: CFData.self)
		let keyLayout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<CoreServices.UCKeyboardLayout>.self)
		var deadKeyState: UInt32 = 0
		let maxLength = 4
		var length = 0
		var characters = [UniChar](repeating: 0, count: maxLength)

		let error = CoreServices.UCKeyTranslate(
			keyLayout,
			UInt16(carbonKeyCode),
			UInt16(CoreServices.kUCKeyActionDisplay),
			0, // No modifiers
			UInt32(LMGetKbdType()),
			OptionBits(CoreServices.kUCKeyTranslateNoDeadKeysBit),
			&deadKeyState,
			maxLength,
			&length,
			&characters
		)

		guard error == noErr else {
			return nil
		}

		let string = String(utf16CodeUnits: characters, count: length)
		if string.count == 1 {
			return string.first
		}

		return nil
	}

	/**
	Key equivalent string in `NSMenuItem` format.

	This can be used to show the keyboard shortcut in a `NSMenuItem` by assigning it to `NSMenuItem#keyEquivalent`.

	- Note: Don't forget to also pass ``Shortcut/modifiers`` to `NSMenuItem#keyEquivalentModifierMask`.
	*/
	@MainActor
	public var nsMenuItemKeyEquivalent: String? {
		if
			let key,
			let specialKey = keyToSpecialKeyMapping[key]
		{
			if let keyEquivalent = specialKey.appKitMenuItemKeyEquivalent {
				return String(keyEquivalent)
			}
		} else if let character = keyToCharacter() {
			return String(character)
		}

		return nil
	}
}

extension KeyboardShortcuts.Shortcut: CustomStringConvertible {
	/**
	The string representation of the keyboard shortcut.

	```swift
	print(KeyboardShortcuts.Shortcut(.a, modifiers: [.command]))
	//=> "⌘A"
	```
	*/

	@MainActor
	var presentableDescription: String {
		if
			let key,
			let specialKey = keyToSpecialKeyMapping[key]
		{
			return modifiers.presentableDescription + specialKey.presentableDescription
		}

		return modifiers.presentableDescription + String(keyToCharacter() ?? "�").capitalized
	}

	@MainActor
	public var description: String {
		// TODO: `description` needs to be `nonisolated`
		presentableDescription
	}
}

extension KeyboardShortcuts.Shortcut {
	@available(macOS 11, *)
	@MainActor
	var toSwiftUI: KeyboardShortcut? {
		if
			let key,
			let specialKey = keyToSpecialKeyMapping[key]
		{
			if let keyEquivalent = specialKey.swiftUIKeyEquivalent {
				if #available(macOS 12.0, *) {
					return KeyboardShortcut(keyEquivalent, modifiers: modifiers.toEventModifiers, localization: .custom)
				} else {
					return KeyboardShortcut(keyEquivalent, modifiers: modifiers.toEventModifiers)
				}
			}
		} else if let character = keyToCharacter() {
			if #available(macOS 12.0, *) {
				return KeyboardShortcut(KeyEquivalent(character), modifiers: modifiers.toEventModifiers, localization: .custom)
			} else {
				return KeyboardShortcut(KeyEquivalent(character), modifiers: modifiers.toEventModifiers)
			}
		}

		return nil
	}
}
#endif
