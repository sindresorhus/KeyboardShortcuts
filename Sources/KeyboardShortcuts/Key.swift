import Cocoa
import Carbon.HIToolbox

extension KeyboardShortcuts {
	// swiftlint:disable identifier_name
	/// Represents a key on the keyboard.
	public struct Key: Hashable, RawRepresentable {
		static let a = Self(kVK_ANSI_A)
		static let b = Self(kVK_ANSI_B)
		static let c = Self(kVK_ANSI_C)
		static let d = Self(kVK_ANSI_D)
		static let e = Self(kVK_ANSI_E)
		static let f = Self(kVK_ANSI_F)
		static let g = Self(kVK_ANSI_G)
		static let h = Self(kVK_ANSI_H)
		static let i = Self(kVK_ANSI_I)
		static let j = Self(kVK_ANSI_J)
		static let k = Self(kVK_ANSI_K)
		static let l = Self(kVK_ANSI_L)
		static let m = Self(kVK_ANSI_M)
		static let n = Self(kVK_ANSI_N)
		static let o = Self(kVK_ANSI_O)
		static let p = Self(kVK_ANSI_P)
		static let q = Self(kVK_ANSI_Q)
		static let r = Self(kVK_ANSI_R)
		static let s = Self(kVK_ANSI_S)
		static let t = Self(kVK_ANSI_T)
		static let u = Self(kVK_ANSI_U)
		static let v = Self(kVK_ANSI_V)
		static let w = Self(kVK_ANSI_W)
		static let x = Self(kVK_ANSI_X)
		static let y = Self(kVK_ANSI_Y)
		static let z = Self(kVK_ANSI_Z)
		// swiftlint:enable identifier_name

		// MARK: Numbers

		static let zero = Self(kVK_ANSI_0)
		static let one = Self(kVK_ANSI_1)
		static let two = Self(kVK_ANSI_2)
		static let three = Self(kVK_ANSI_3)
		static let four = Self(kVK_ANSI_4)
		static let five = Self(kVK_ANSI_5)
		static let six = Self(kVK_ANSI_6)
		static let seven = Self(kVK_ANSI_7)
		static let eight = Self(kVK_ANSI_8)
		static let nine = Self(kVK_ANSI_9)

		// MARK: Modifiers

		static let capsLock = Self(kVK_CapsLock)
		static let shift = Self(kVK_Shift)
		static let function = Self(kVK_Function)
		static let control = Self(kVK_Control)
		static let option = Self(kVK_Option)
		static let command = Self(kVK_Command)
		static let rightCommand = Self(kVK_RightCommand)
		static let rightOption = Self(kVK_RightOption)
		static let rightControl = Self(kVK_RightControl)
		static let rightShift = Self(kVK_RightShift)

		// MARK: Miscellaneous

		static let `return` = Self(kVK_Return)
		static let backslash = Self(kVK_ANSI_Backslash)
		static let backtick = Self(kVK_ANSI_Grave)
		static let comma = Self(kVK_ANSI_Comma)
		static let equal = Self(kVK_ANSI_Equal)
		static let minus = Self(kVK_ANSI_Minus)
		static let period = Self(kVK_ANSI_Period)
		static let quote = Self(kVK_ANSI_Quote)
		static let semicolon = Self(kVK_ANSI_Semicolon)
		static let slash = Self(kVK_ANSI_Slash)
		static let space = Self(kVK_Space)
		static let tab = Self(kVK_Tab)
		static let leftBracket = Self(kVK_ANSI_LeftBracket)
		static let rightBracket = Self(kVK_ANSI_RightBracket)
		static let pageUp = Self(kVK_PageUp)
		static let pageDown = Self(kVK_PageDown)
		static let home = Self(kVK_Home)
		static let end = Self(kVK_End)
		static let upArrow = Self(kVK_UpArrow)
		static let rightArrow = Self(kVK_RightArrow)
		static let downArrow = Self(kVK_DownArrow)
		static let leftArrow = Self(kVK_LeftArrow)
		static let escape = Self(kVK_Escape)
		static let delete = Self(kVK_Delete)
		static let deleteForward = Self(kVK_ForwardDelete)
		static let help = Self(kVK_Help)
		static let mute = Self(kVK_Mute)
		static let volumeUp = Self(kVK_VolumeUp)
		static let volumeDown = Self(kVK_VolumeDown)

		// MARK: Function

		static let f1 = Self(kVK_F1)
		static let f2 = Self(kVK_F2)
		static let f3 = Self(kVK_F3)
		static let f4 = Self(kVK_F4)
		static let f5 = Self(kVK_F5)
		static let f6 = Self(kVK_F6)
		static let f7 = Self(kVK_F7)
		static let f8 = Self(kVK_F8)
		static let f9 = Self(kVK_F9)
		static let f10 = Self(kVK_F10)
		static let f11 = Self(kVK_F11)
		static let f12 = Self(kVK_F12)
		static let f13 = Self(kVK_F13)
		static let f14 = Self(kVK_F14)
		static let f15 = Self(kVK_F15)
		static let f16 = Self(kVK_F16)
		static let f17 = Self(kVK_F17)
		static let f18 = Self(kVK_F18)
		static let f19 = Self(kVK_F19)
		static let f20 = Self(kVK_F20)

		// MARK: Keypad

		static let keypad0 = Self(kVK_ANSI_Keypad0)
		static let keypad1 = Self(kVK_ANSI_Keypad1)
		static let keypad2 = Self(kVK_ANSI_Keypad2)
		static let keypad3 = Self(kVK_ANSI_Keypad3)
		static let keypad4 = Self(kVK_ANSI_Keypad4)
		static let keypad5 = Self(kVK_ANSI_Keypad5)
		static let keypad6 = Self(kVK_ANSI_Keypad6)
		static let keypad7 = Self(kVK_ANSI_Keypad7)
		static let keypad8 = Self(kVK_ANSI_Keypad8)
		static let keypad9 = Self(kVK_ANSI_Keypad9)
		static let keypadClear = Self(kVK_ANSI_KeypadClear)
		static let keypadDecimal = Self(kVK_ANSI_KeypadDecimal)
		static let keypadDivide = Self(kVK_ANSI_KeypadDivide)
		static let keypadEnter = Self(kVK_ANSI_KeypadEnter)
		static let keypadEquals = Self(kVK_ANSI_KeypadEquals)
		static let keypadMinus = Self(kVK_ANSI_KeypadMinus)
		static let keypadMultiply = Self(kVK_ANSI_KeypadMultiply)
		static let keypadPlus = Self(kVK_ANSI_KeypadPlus)

		// MARK: Properties

		/// The raw key code.
		public let rawValue: Int

		// MARK: Initializers

		/// Create a `Key` from a key code.
		public init(rawValue: Int) {
			self.rawValue = rawValue
		}

		private init(_ value: Int) {
			self.init(rawValue: value)
		}
	}
}

extension KeyboardShortcuts.Key {
	/// All the function keys.
	static let functionKeys: Set<Self> = [
		.f1,
		.f2,
		.f3,
		.f4,
		.f5,
		.f6,
		.f7,
		.f8,
		.f9,
		.f10,
		.f11,
		.f12,
		.f13,
		.f14,
		.f15,
		.f16,
		.f17,
		.f18,
		.f19,
		.f20
	]

	/// Returns true if the key is a function key. For example, `F1`.
	var isFunctionKey: Bool { Self.functionKeys.contains(self) }
}
