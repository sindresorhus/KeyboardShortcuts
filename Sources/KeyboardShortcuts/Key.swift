import Cocoa
import Carbon.HIToolbox

extension KeyboardShortcuts {
	// swiftlint:disable identifier_name
	/// Represents a key on the keyboard.
	public enum Key: RawRepresentable {
		case a
		case b
		case c
		case d
		case e
		case f
		case g
		case h
		case i
		case j
		case k
		case l
		case m
		case n
		case o
		case p
		case q
		case r
		case s
		case t
		case u
		case v
		case w
		case x
		case y
		case z

		case zero
		case one
		case two
		case three
		case four
		case five
		case six
		case seven
		case eight
		case nine

		case backslash
		case backtick
		case comma
		case equal
		case escape
		case leftBracket
		case minus
		case period
		case quote
		case rightBracket
		case semicolon
		case slash
		case space

		// `NSEvent.SpecialKey`
		case backTab
		case backspace
		case begin
		case `break`
		case carriageReturn
		case clearDisplay
		case clearLine
		case delete
		case deleteCharacter
		case deleteForward
		case deleteLine
		case downArrow
		case end
		case enter
		case execute
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
		case f21
		case f22
		case f23
		case f24
		case f25
		case f26
		case f27
		case f28
		case f29
		case f30
		case f31
		case f32
		case f33
		case f34
		case f35
		case find
		case formFeed
		case help
		case home
		case insert
		case insertCharacter
		case insertLine
		case leftArrow
		case lineSeparator
		case menu
		case modeSwitch
		case newline
		case next
		case pageDown
		case pageUp
		case paragraphSeparator
		case pause
		case prev
		case print
		case printScreen
		case redo
		case reset
		case rightArrow
		case scrollLock
		case select
		case stop
		case sysReq
		case system
		case tab
		case undo
		case upArrow
		case user
		// swiftlint:enable identifier_name

		/// Create a `Key` from a key code.
		public init?(rawValue: Int) {
			switch rawValue {
			case kVK_ANSI_A:
				self = .a
			case kVK_ANSI_B:
				self = .b
			case kVK_ANSI_C:
				self = .c
			case kVK_ANSI_D:
				self = .d
			case kVK_ANSI_E:
				self = .e
			case kVK_ANSI_F:
				self = .f
			case kVK_ANSI_G:
				self = .g
			case kVK_ANSI_H:
				self = .h
			case kVK_ANSI_I:
				self = .i
			case kVK_ANSI_J:
				self = .j
			case kVK_ANSI_K:
				self = .k
			case kVK_ANSI_L:
				self = .l
			case kVK_ANSI_M:
				self = .m
			case kVK_ANSI_N:
				self = .n
			case kVK_ANSI_O:
				self = .o
			case kVK_ANSI_P:
				self = .p
			case kVK_ANSI_Q:
				self = .q
			case kVK_ANSI_R:
				self = .r
			case kVK_ANSI_S:
				self = .s
			case kVK_ANSI_T:
				self = .t
			case kVK_ANSI_U:
				self = .u
			case kVK_ANSI_V:
				self = .v
			case kVK_ANSI_W:
				self = .w
			case kVK_ANSI_X:
				self = .x
			case kVK_ANSI_Y:
				self = .y
			case kVK_ANSI_Z:
				self = .z
			case kVK_ANSI_0:
				self = .zero
			case kVK_ANSI_1:
				self = .one
			case kVK_ANSI_2:
				self = .two
			case kVK_ANSI_3:
				self = .three
			case kVK_ANSI_4:
				self = .four
			case kVK_ANSI_5:
				self = .five
			case kVK_ANSI_6:
				self = .six
			case kVK_ANSI_7:
				self = .seven
			case kVK_ANSI_8:
				self = .eight
			case kVK_ANSI_9:
				self = .nine
			case kVK_ANSI_Backslash:
				self = .backslash
			case kVK_ANSI_Grave:
				self = .backtick
			case kVK_ANSI_Comma:
				self = .comma
			case kVK_ANSI_Equal:
				self = .equal
			case kVK_Escape:
				self = .escape
			case kVK_ANSI_LeftBracket:
				self = .leftBracket
			case kVK_ANSI_Minus:
				self = .minus
			case kVK_ANSI_Period:
				self = .period
			case kVK_ANSI_Quote:
				self = .quote
			case kVK_ANSI_RightBracket:
				self = .rightBracket
			case kVK_ANSI_Semicolon:
				self = .semicolon
			case kVK_ANSI_Slash:
				self = .slash
			case kVK_Space:
				self = .space
			default:
				self.init(specialKey: .init(rawValue: rawValue))
			}
		}

		private init?(specialKey: NSEvent.SpecialKey) {
			switch specialKey {
			case .backTab:
				self = .backTab
			case .backspace:
				self = .backspace
			case .begin:
				self = .begin
			case .break:
				self = .break
			case .carriageReturn:
				self = .carriageReturn
			case .clearDisplay:
				self = .clearDisplay
			case .clearLine:
				self = .clearLine
			case .delete:
				self = .delete
			case .deleteCharacter:
				self = .deleteCharacter
			case .deleteForward:
				self = .deleteForward
			case .deleteLine:
				self = .deleteLine
			case .downArrow:
				self = .downArrow
			case .end:
				self = .end
			case .enter:
				self = .enter
			case .execute:
				self = .execute
			case .f1:
				self = .f1
			case .f2:
				self = .f2
			case .f3:
				self = .f3
			case .f4:
				self = .f4
			case .f5:
				self = .f5
			case .f6:
				self = .f6
			case .f7:
				self = .f7
			case .f8:
				self = .f8
			case .f9:
				self = .f9
			case .f10:
				self = .f10
			case .f11:
				self = .f11
			case .f12:
				self = .f12
			case .f13:
				self = .f13
			case .f14:
				self = .f14
			case .f15:
				self = .f15
			case .f16:
				self = .f16
			case .f17:
				self = .f17
			case .f18:
				self = .f18
			case .f19:
				self = .f19
			case .f20:
				self = .f20
			case .f21:
				self = .f21
			case .f22:
				self = .f22
			case .f23:
				self = .f23
			case .f24:
				self = .f24
			case .f25:
				self = .f25
			case .f26:
				self = .f26
			case .f27:
				self = .f27
			case .f28:
				self = .f28
			case .f29:
				self = .f29
			case .f30:
				self = .f30
			case .f31:
				self = .f31
			case .f32:
				self = .f32
			case .f33:
				self = .f33
			case .f34:
				self = .f34
			case .f35:
				self = .f35
			case .find:
				self = .find
			case .formFeed:
				self = .formFeed
			case .help:
				self = .help
			case .home:
				self = .home
			case .insert:
				self = .insert
			case .insertCharacter:
				self = .insertCharacter
			case .insertLine:
				self = .insertLine
			case .leftArrow:
				self = .leftArrow
			case .lineSeparator:
				self = .lineSeparator
			case .menu:
				self = .menu
			case .modeSwitch:
				self = .modeSwitch
			case .newline:
				self = .newline
			case .next:
				self = .next
			case .pageDown:
				self = .pageDown
			case .pageUp:
				self = .pageUp
			case .paragraphSeparator:
				self = .paragraphSeparator
			case .pause:
				self = .pause
			case .prev:
				self = .prev
			case .print:
				self = .print
			case .printScreen:
				self = .printScreen
			case .redo:
				self = .redo
			case .reset:
				self = .reset
			case .rightArrow:
				self = .rightArrow
			case .scrollLock:
				self = .scrollLock
			case .select:
				self = .select
			case .stop:
				self = .stop
			case .sysReq:
				self = .sysReq
			case .system:
				self = .system
			case .tab:
				self = .tab
			case .undo:
				self = .undo
			case .upArrow:
				self = .upArrow
			case .user:
				self = .user
			default:
				return nil
			}
		}

		private var specialKey: NSEvent.SpecialKey? {
			switch self {
			case .backTab:
				return .backTab
			case .backspace:
				return .backspace
			case .begin:
				return .begin
			case .break:
				return .break
			case .carriageReturn:
				return .carriageReturn
			case .clearDisplay:
				return .clearDisplay
			case .clearLine:
				return .clearLine
			case .delete:
				return .delete
			case .deleteCharacter:
				return .deleteCharacter
			case .deleteForward:
				return .deleteForward
			case .deleteLine:
				return .deleteLine
			case .downArrow:
				return .downArrow
			case .end:
				return .end
			case .enter:
				return .enter
			case .execute:
				return .execute
			case .f1:
				return .f1
			case .f2:
				return .f2
			case .f3:
				return .f3
			case .f4:
				return .f4
			case .f5:
				return .f5
			case .f6:
				return .f6
			case .f7:
				return .f7
			case .f8:
				return .f8
			case .f9:
				return .f9
			case .f10:
				return .f10
			case .f11:
				return .f11
			case .f12:
				return .f12
			case .f13:
				return .f13
			case .f14:
				return .f14
			case .f15:
				return .f15
			case .f16:
				return .f16
			case .f17:
				return .f17
			case .f18:
				return .f18
			case .f19:
				return .f19
			case .f20:
				return .f20
			case .f21:
				return .f21
			case .f22:
				return .f22
			case .f23:
				return .f23
			case .f24:
				return .f24
			case .f25:
				return .f25
			case .f26:
				return .f26
			case .f27:
				return .f27
			case .f28:
				return .f28
			case .f29:
				return .f29
			case .f30:
				return .f30
			case .f31:
				return .f31
			case .f32:
				return .f32
			case .f33:
				return .f33
			case .f34:
				return .f34
			case .f35:
				return .f35
			case .find:
				return .find
			case .formFeed:
				return .formFeed
			case .help:
				return .help
			case .home:
				return .home
			case .insert:
				return .insert
			case .insertCharacter:
				return .insertCharacter
			case .insertLine:
				return .insertLine
			case .leftArrow:
				return .leftArrow
			case .lineSeparator:
				return .lineSeparator
			case .menu:
				return .menu
			case .modeSwitch:
				return .modeSwitch
			case .newline:
				return .newline
			case .next:
				return .next
			case .pageDown:
				return .pageDown
			case .pageUp:
				return .pageUp
			case .paragraphSeparator:
				return .paragraphSeparator
			case .pause:
				return .pause
			case .prev:
				return .prev
			case .print:
				return .print
			case .printScreen:
				return .printScreen
			case .redo:
				return .redo
			case .reset:
				return .reset
			case .rightArrow:
				return .rightArrow
			case .scrollLock:
				return .scrollLock
			case .select:
				return .select
			case .stop:
				return .stop
			case .sysReq:
				return .sysReq
			case .system:
				return .system
			case .tab:
				return .tab
			case .undo:
				return .undo
			case .upArrow:
				return .upArrow
			case .user:
				return .user
			default:
				return nil
			}
		}

		/// The raw key code.
		public var rawValue: Int {
			switch self {
			case .a:
				return kVK_ANSI_A
			case .b:
				return kVK_ANSI_B
			case .c:
				return kVK_ANSI_C
			case .d:
				return kVK_ANSI_D
			case .e:
				return kVK_ANSI_E
			case .f:
				return kVK_ANSI_F
			case .g:
				return kVK_ANSI_G
			case .h:
				return kVK_ANSI_H
			case .i:
				return kVK_ANSI_I
			case .j:
				return kVK_ANSI_J
			case .k:
				return kVK_ANSI_K
			case .l:
				return kVK_ANSI_L
			case .m:
				return kVK_ANSI_M
			case .n:
				return kVK_ANSI_N
			case .o:
				return kVK_ANSI_O
			case .p:
				return kVK_ANSI_P
			case .q:
				return kVK_ANSI_Q
			case .r:
				return kVK_ANSI_R
			case .s:
				return kVK_ANSI_S
			case .t:
				return kVK_ANSI_T
			case .u:
				return kVK_ANSI_U
			case .v:
				return kVK_ANSI_V
			case .w:
				return kVK_ANSI_W
			case .x:
				return kVK_ANSI_X
			case .y:
				return kVK_ANSI_Y
			case .z:
				return kVK_ANSI_Z
			case .zero:
				return kVK_ANSI_0
			case .one:
				return kVK_ANSI_1
			case .two:
				return kVK_ANSI_2
			case .three:
				return kVK_ANSI_3
			case .four:
				return kVK_ANSI_4
			case .five:
				return kVK_ANSI_5
			case .six:
				return kVK_ANSI_6
			case .seven:
				return kVK_ANSI_7
			case .eight:
				return kVK_ANSI_8
			case .nine:
				return kVK_ANSI_9
			case .backslash:
				return kVK_ANSI_Backslash
			case .backtick:
				return kVK_ANSI_Grave
			case .comma:
				return kVK_ANSI_Comma
			case .equal:
				return kVK_ANSI_Equal
			case .escape:
				return kVK_Escape
			case .leftBracket:
				return kVK_ANSI_LeftBracket
			case .minus:
				return kVK_ANSI_Minus
			case .period:
				return kVK_ANSI_Period
			case .quote:
				return kVK_ANSI_Quote
			case .rightBracket:
				return kVK_ANSI_RightBracket
			case .semicolon:
				return kVK_ANSI_Semicolon
			case .slash:
				return kVK_ANSI_Slash
			case .space:
				return kVK_Space
			case .backTab, .backspace, .begin, .break, .carriageReturn, .clearDisplay, .clearLine, .delete, .deleteCharacter, .deleteForward, .deleteLine, .downArrow, .end, .enter, .execute, .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12, .f13, .f14, .f15, .f16, .f17, .f18, .f19, .f20, .f21, .f22, .f23, .f24, .f25, .f26, .f27, .f28, .f29, .f30, .f31, .f32, .f33, .f34, .f35, .find, .formFeed, .help, .home, .insert, .insertCharacter, .insertLine, .leftArrow, .lineSeparator, .menu, .modeSwitch, .newline, .next, .pageDown, .pageUp, .paragraphSeparator, .pause, .prev, .print, .printScreen, .redo, .reset, .rightArrow, .scrollLock, .select, .stop, .sysReq, .system, .tab, .undo, .upArrow, .user:
				return specialKey?.rawValue ?? 0
			}
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
		.f20,
		.f21,
		.f22,
		.f23,
		.f24,
		.f25,
		.f26,
		.f27,
		.f28,
		.f29,
		.f30,
		.f31,
		.f32,
		.f33,
		.f34,
		.f35
	]

	/// Returns true if the key is a function key. For example, `F1`.
	var isFunctionKey: Bool { Self.functionKeys.contains(self) }
}
