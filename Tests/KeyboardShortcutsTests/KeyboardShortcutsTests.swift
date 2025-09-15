import XCTest
import KeyboardShortcuts

final class KeyboardShortcutsTests: XCTestCase {
	override func setUpWithError() throws {
		UserDefaults.standard.removeAll()
	}

	func testSetShortcutAndReset() throws {
		let defaultShortcut = KeyboardShortcuts.Shortcut(.c)
		let shortcut1 = KeyboardShortcuts.Shortcut(.a)
		let shortcut2 = KeyboardShortcuts.Shortcut(.b)

		let shortcutName1 = KeyboardShortcuts.Name("testSetShortcutAndReset1")
		let shortcutName2 = KeyboardShortcuts.Name("testSetShortcutAndReset2", default: defaultShortcut)

		KeyboardShortcuts.setShortcut(shortcut1, for: shortcutName1)
		KeyboardShortcuts.setShortcut(shortcut2, for: shortcutName2)

		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: shortcutName1), shortcut1)
		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: shortcutName2), shortcut2)

		KeyboardShortcuts.reset(shortcutName1, shortcutName2)

		XCTAssertNil(KeyboardShortcuts.getShortcut(for: shortcutName1))
		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: shortcutName2), defaultShortcut)
	}

	func testShortcutCreation() throws {
		let shortcut1 = KeyboardShortcuts.Shortcut(.a)
		let shortcut2 = KeyboardShortcuts.Shortcut(.a, modifiers: [.command])
		let shortcut3 = KeyboardShortcuts.Shortcut(.a, modifiers: [.command, .shift])

		XCTAssertEqual(shortcut1.key, .a)
		XCTAssertEqual(shortcut1.modifiers, [])

		XCTAssertEqual(shortcut2.key, .a)
		XCTAssertEqual(shortcut2.modifiers, [.command])

		XCTAssertEqual(shortcut3.key, .a)
		XCTAssertEqual(shortcut3.modifiers, [.command, .shift])
	}

	func testShortcutEquality() throws {
		let shortcut1 = KeyboardShortcuts.Shortcut(.a, modifiers: [.command])
		let shortcut2 = KeyboardShortcuts.Shortcut(.a, modifiers: [.command])
		let shortcut3 = KeyboardShortcuts.Shortcut(.b, modifiers: [.command])

		XCTAssertEqual(shortcut1, shortcut2)
		XCTAssertNotEqual(shortcut1, shortcut3)
	}

	func testNameEquality() throws {
		let name1 = KeyboardShortcuts.Name("test")
		let name2 = KeyboardShortcuts.Name("test")
		let name3 = KeyboardShortcuts.Name("different")

		XCTAssertEqual(name1, name2)
		XCTAssertNotEqual(name1, name3)
	}

	func testNameWithDefault() throws {
		let defaultShortcut = KeyboardShortcuts.Shortcut(.space)
		let name = KeyboardShortcuts.Name("testDefault", default: defaultShortcut)

		// Should return default when no value is set
		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: name), defaultShortcut)

		// Setting a value should override the default
		let customShortcut = KeyboardShortcuts.Shortcut(.tab)
		KeyboardShortcuts.setShortcut(customShortcut, for: name)
		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: name), customShortcut)

		// Resetting should restore the default
		KeyboardShortcuts.reset(name)
		XCTAssertEqual(KeyboardShortcuts.getShortcut(for: name), defaultShortcut)
	}
}
