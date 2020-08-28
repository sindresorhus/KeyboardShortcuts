import XCTest
import KeyboardShortcuts

final class KeyboardShortcutsTests: XCTestCase {
	// TODO: Add more tests.

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
}
