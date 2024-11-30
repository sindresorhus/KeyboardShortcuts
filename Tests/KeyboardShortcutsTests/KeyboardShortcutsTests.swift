import XCTest
@testable import KeyboardShortcuts

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

	func testRemoveHandlersForNames() throws {
		let shortcut1 = KeyboardShortcuts.Shortcut(.a)
		let shortcut2 = KeyboardShortcuts.Shortcut(.b)

		let shortcutName1 = KeyboardShortcuts.Name("testRemoveHandlersForNames1")
		let shortcutName2 = KeyboardShortcuts.Name("testRemoveHandlersForNames2")

		KeyboardShortcuts.setShortcut(shortcut1, for: shortcutName1)
		KeyboardShortcuts.setShortcut(shortcut2, for: shortcutName2)

		KeyboardShortcuts.onKeyDown(for: shortcutName1) {
			print("Shortcut 1 is down")
		}
		KeyboardShortcuts.onKeyUp(for: shortcutName1) {
			print("Shortcut 1 is up")
		}
		KeyboardShortcuts.onKeyDown(for: shortcutName2) {
			print("Shortcut 2 is down")
		}
		KeyboardShortcuts.onKeyUp(for: shortcutName2) {
			print("Shortcut 2 is up")
		}

		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName1]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName2]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName1]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName2]?.count, 1)

		KeyboardShortcuts.removeHandlers(for: [shortcutName1])

		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName1]?.count, 0)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName2]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName1]?.count, 0)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName2]?.count, 1)

		KeyboardShortcuts.removeHandlers(for: [shortcutName2])

		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName1]?.count, 0)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName2]?.count, 0)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName1]?.count, 0)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName2]?.count, 0)
	}

	func testRemoveKeyDownHandlersForNames() throws {
		let shortcut1 = KeyboardShortcuts.Shortcut(.a)
		let shortcut2 = KeyboardShortcuts.Shortcut(.b)

		let shortcutName1 = KeyboardShortcuts.Name("testRemoveKeyDownHandlersForNames1")
		let shortcutName2 = KeyboardShortcuts.Name("testRemoveKeyDownHandlersForNames2")

		KeyboardShortcuts.setShortcut(shortcut1, for: shortcutName1)
		KeyboardShortcuts.setShortcut(shortcut2, for: shortcutName2)

		KeyboardShortcuts.onKeyDown(for: shortcutName1) {
			print("Shortcut 1 is down")
		}
		KeyboardShortcuts.onKeyUp(for: shortcutName1) {
			print("Shortcut 1 is up")
		}
		KeyboardShortcuts.onKeyDown(for: shortcutName2) {
			print("Shortcut 2 is down")
		}
		KeyboardShortcuts.onKeyUp(for: shortcutName2) {
			print("Shortcut 2 is up")
		}

		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName1]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName2]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName1]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName2]?.count, 1)

		KeyboardShortcuts.removeKeyDownHandlers(for: [shortcutName1])

		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName1]?.count, 0)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName2]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName1]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName2]?.count, 1)

		KeyboardShortcuts.removeKeyDownHandlers(for: [shortcutName2])

		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName1]?.count, 0)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName2]?.count, 0)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName1]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName2]?.count, 1)
	}

	func testRemoveKeyUpHandlersForNames() throws {
		let shortcut1 = KeyboardShortcuts.Shortcut(.a)
		let shortcut2 = KeyboardShortcuts.Shortcut(.b)

		let shortcutName1 = KeyboardShortcuts.Name("testRemoveKeyUpHandlersForNames1")
		let shortcutName2 = KeyboardShortcuts.Name("testRemoveKeyUpHandlersForNames2")

		KeyboardShortcuts.setShortcut(shortcut1, for: shortcutName1)
		KeyboardShortcuts.setShortcut(shortcut2, for: shortcutName2)

		KeyboardShortcuts.onKeyDown(for: shortcutName1) {
			print("Shortcut 1 is down")
		}
		KeyboardShortcuts.onKeyUp(for: shortcutName1) {
			print("Shortcut 1 is up")
		}
		KeyboardShortcuts.onKeyDown(for: shortcutName2) {
			print("Shortcut 2 is down")
		}
		KeyboardShortcuts.onKeyUp(for: shortcutName2) {
			print("Shortcut 2 is up")
		}

		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName1]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName2]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName1]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName2]?.count, 1)

		KeyboardShortcuts.removeKeyUpHandlers(for: [shortcutName1])

		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName1]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName2]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName1]?.count, 0)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName2]?.count, 1)

		KeyboardShortcuts.removeKeyUpHandlers(for: [shortcutName2])

		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName1]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyDownHandlers[shortcutName2]?.count, 1)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName1]?.count, 0)
		XCTAssertEqual(KeyboardShortcuts.legacyKeyUpHandlers[shortcutName2]?.count, 0)
	}
}
