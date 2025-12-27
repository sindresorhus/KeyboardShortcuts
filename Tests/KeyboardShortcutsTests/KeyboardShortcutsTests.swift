import Testing
import Foundation
import AppKit
@testable import KeyboardShortcuts

@Suite("KeyboardShortcuts Tests", .serialized)
struct KeyboardShortcutsTests {
	init() {
		UserDefaults.standard.removeAllKeyboardShortcuts()
	}

	@Test("Set shortcut and reset")
	func testSetShortcutAndReset() throws {
		let defaultShortcut = KeyboardShortcuts.Shortcut(.c)
		let shortcut1 = KeyboardShortcuts.Shortcut(.a)
		let shortcut2 = KeyboardShortcuts.Shortcut(.b)

		let shortcutName1 = KeyboardShortcuts.Name("testSetShortcutAndReset1")
		let shortcutName2 = KeyboardShortcuts.Name("testSetShortcutAndReset2", default: defaultShortcut)

		KeyboardShortcuts.setShortcut(shortcut1, for: shortcutName1)
		KeyboardShortcuts.setShortcut(shortcut2, for: shortcutName2)

		#expect(KeyboardShortcuts.getShortcut(for: shortcutName1) == shortcut1)
		#expect(KeyboardShortcuts.getShortcut(for: shortcutName2) == shortcut2)

		KeyboardShortcuts.reset(shortcutName1, shortcutName2)

		#expect(KeyboardShortcuts.getShortcut(for: shortcutName1) == nil)
		#expect(KeyboardShortcuts.getShortcut(for: shortcutName2) == defaultShortcut)
	}

	@Test("Shortcut creation")
	func testShortcutCreation() throws {
		let shortcut1 = KeyboardShortcuts.Shortcut(.a)
		let shortcut2 = KeyboardShortcuts.Shortcut(.a, modifiers: [.command])
		let shortcut3 = KeyboardShortcuts.Shortcut(.a, modifiers: [.command, .shift])

		#expect(shortcut1.key == .a)
		#expect(shortcut1.modifiers == [])

		#expect(shortcut2.key == .a)
		#expect(shortcut2.modifiers == [.command])

		#expect(shortcut3.key == .a)
		#expect(shortcut3.modifiers == [.command, .shift])
	}

	@Test("Shortcut equality")
	func testShortcutEquality() throws {
		let shortcut1 = KeyboardShortcuts.Shortcut(.a, modifiers: [.command])
		let shortcut2 = KeyboardShortcuts.Shortcut(.a, modifiers: [.command])
		let shortcut3 = KeyboardShortcuts.Shortcut(.b, modifiers: [.command])
		let shortcut4 = KeyboardShortcuts.Shortcut(.a, modifiers: [.option])

		#expect(shortcut1 == shortcut2)
		#expect(shortcut1 != shortcut3)
		#expect(shortcut1 != shortcut4)

		// Test hashability
		let set = Set([shortcut1, shortcut2, shortcut3, shortcut4])
		#expect(set.count == 3) // shortcut1 and shortcut2 are equal
	}

	@Test("Name equality")
	func testNameEquality() throws {
		let name1 = KeyboardShortcuts.Name("test")
		let name2 = KeyboardShortcuts.Name("test")
		let name3 = KeyboardShortcuts.Name("different")

		#expect(name1 == name2)
		#expect(name1 != name3)
	}

	@Test("Name with default")
	func testNameWithDefault() throws {
		let defaultShortcut = KeyboardShortcuts.Shortcut(.space)
		let name = KeyboardShortcuts.Name("testDefault", default: defaultShortcut)

		// Should return default when no value is set
		#expect(KeyboardShortcuts.getShortcut(for: name) == defaultShortcut)

		// Setting a value should override the default
		let customShortcut = KeyboardShortcuts.Shortcut(.tab)
		KeyboardShortcuts.setShortcut(customShortcut, for: name)
		#expect(KeyboardShortcuts.getShortcut(for: name) == customShortcut)

		// Resetting should restore the default
		KeyboardShortcuts.reset(name)
		#expect(KeyboardShortcuts.getShortcut(for: name) == defaultShortcut)
	}

	@Test("Shortcut name validation")
	func testShortcutNameValidation() {
		#expect(KeyboardShortcuts.isValidShortcutName("validName"))
		#expect(!KeyboardShortcuts.isValidShortcutName("invalid.name"))
	}

	@Test("Shortcut persistence")
	func testShortcutPersistence() throws {
		let name = KeyboardShortcuts.Name("persistenceTest")
		let shortcut = KeyboardShortcuts.Shortcut(.f1, modifiers: [.command, .option])

		KeyboardShortcuts.setShortcut(shortcut, for: name)
		#expect(KeyboardShortcuts.getShortcut(for: name) == shortcut)

		// Simulate app restart by creating new name with same identifier
		let sameName = KeyboardShortcuts.Name("persistenceTest")
		#expect(KeyboardShortcuts.getShortcut(for: sameName) == shortcut)
	}

	@Test("Multiple shortcuts")
	func testMultipleShortcuts() throws {
		let name1 = KeyboardShortcuts.Name("multi1")
		let name2 = KeyboardShortcuts.Name("multi2")
		let name3 = KeyboardShortcuts.Name("multi3")

		let shortcut1 = KeyboardShortcuts.Shortcut(.a, modifiers: [.command])
		let shortcut2 = KeyboardShortcuts.Shortcut(.b, modifiers: [.option])
		let shortcut3 = KeyboardShortcuts.Shortcut(.c, modifiers: [.shift])

		KeyboardShortcuts.setShortcut(shortcut1, for: name1)
		KeyboardShortcuts.setShortcut(shortcut2, for: name2)
		KeyboardShortcuts.setShortcut(shortcut3, for: name3)

		#expect(KeyboardShortcuts.getShortcut(for: name1) == shortcut1)
		#expect(KeyboardShortcuts.getShortcut(for: name2) == shortcut2)
		#expect(KeyboardShortcuts.getShortcut(for: name3) == shortcut3)
	}

	@Test("Removing shortcuts")
	func testRemovingShortcuts() throws {
		let name = KeyboardShortcuts.Name("removeTest")
		let shortcut = KeyboardShortcuts.Shortcut(.delete, modifiers: [.command])

		KeyboardShortcuts.setShortcut(shortcut, for: name)
		#expect(KeyboardShortcuts.getShortcut(for: name) == shortcut)

		KeyboardShortcuts.setShortcut(nil, for: name)
		#expect(KeyboardShortcuts.getShortcut(for: name) == nil)
	}

	@Test("Empty modifiers")
	func testEmptyModifiers() throws {
		let shortcut = KeyboardShortcuts.Shortcut(.a, modifiers: [])
		#expect(shortcut.modifiers.isEmpty)
		#expect(shortcut.modifiers.ks_symbolicRepresentation == "")
	}

	@Test("Function keys")
	func testFunctionKeys() throws {
		let f1 = KeyboardShortcuts.Shortcut(.f1)
		let f12 = KeyboardShortcuts.Shortcut(.f12)
		let f20 = KeyboardShortcuts.Shortcut(.f20)

		#expect(f1.key == .f1)
		#expect(f12.key == .f12)
		#expect(f20.key == .f20)
	}

	@Test("Special keys")
	func testSpecialKeys() throws {
		let space = KeyboardShortcuts.Shortcut(.space)
		let tab = KeyboardShortcuts.Shortcut(.tab)
		let escape = KeyboardShortcuts.Shortcut(.escape)
		let delete = KeyboardShortcuts.Shortcut(.delete)
		let returnKey = KeyboardShortcuts.Shortcut(.return)

		#expect(space.key == .space)
		#expect(tab.key == .tab)
		#expect(escape.key == .escape)
		#expect(delete.key == .delete)
		#expect(returnKey.key == .return)
	}

	@Test("Keypad keys")
	func testKeypadKeys() throws {
		let keypad0 = KeyboardShortcuts.Shortcut(.keypad0)
		let keypad9 = KeyboardShortcuts.Shortcut(.keypad9)
		let keypadPlus = KeyboardShortcuts.Shortcut(.keypadPlus)
		let keypadEnter = KeyboardShortcuts.Shortcut(.keypadEnter)

		#expect(keypad0.key == .keypad0)
		#expect(keypad9.key == .keypad9)
		#expect(keypadPlus.key == .keypadPlus)
		#expect(keypadEnter.key == .keypadEnter)
	}

	@Test("Arrow keys")
	func testArrowKeys() throws {
		let up = KeyboardShortcuts.Shortcut(.upArrow, modifiers: [.command])
		let down = KeyboardShortcuts.Shortcut(.downArrow, modifiers: [.command])
		let left = KeyboardShortcuts.Shortcut(.leftArrow, modifiers: [.command])
		let right = KeyboardShortcuts.Shortcut(.rightArrow, modifiers: [.command])

		#expect(up.key == .upArrow)
		#expect(down.key == .downArrow)
		#expect(left.key == .leftArrow)
		#expect(right.key == .rightArrow)
		#expect(up.modifiers == [.command])
	}

	@Test("Name identity")
	func testNameIdentity() throws {
		let name1 = KeyboardShortcuts.Name("sameName")
		let name2 = KeyboardShortcuts.Name("sameName")
		#expect(name1 == name2)
		#expect(name1.hashValue == name2.hashValue)
	}

	@Test("Default values")
	func testDefaultValues() throws {
		let defaultShortcut = KeyboardShortcuts.Shortcut(.d, modifiers: [.command])
		let nameWithDefault = KeyboardShortcuts.Name("withDefault", default: defaultShortcut)
		let nameWithoutDefault = KeyboardShortcuts.Name("withoutDefault")

		#expect(KeyboardShortcuts.getShortcut(for: nameWithDefault) == defaultShortcut)
		#expect(KeyboardShortcuts.getShortcut(for: nameWithoutDefault) == nil)
	}

	@Test("Overriding defaults")
	func testOverridingDefaults() throws {
		let defaultShortcut = KeyboardShortcuts.Shortcut(.x, modifiers: [.control])
		let name = KeyboardShortcuts.Name("override", default: defaultShortcut)

		let newShortcut = KeyboardShortcuts.Shortcut(.y, modifiers: [.option])
		KeyboardShortcuts.setShortcut(newShortcut, for: name)

		#expect(KeyboardShortcuts.getShortcut(for: name) == newShortcut)

		// Reset should restore default
		KeyboardShortcuts.reset(name)
		#expect(KeyboardShortcuts.getShortcut(for: name) == defaultShortcut)
	}

	@Test("Batch reset")
	func testBatchReset() throws {
		let name1 = KeyboardShortcuts.Name("batch1", default: .init(.a))
		let name2 = KeyboardShortcuts.Name("batch2", default: .init(.b))
		let name3 = KeyboardShortcuts.Name("batch3")

		KeyboardShortcuts.setShortcut(.init(.x), for: name1)
		KeyboardShortcuts.setShortcut(.init(.y), for: name2)
		KeyboardShortcuts.setShortcut(.init(.z), for: name3)

		KeyboardShortcuts.reset(name1, name2, name3)

		#expect(KeyboardShortcuts.getShortcut(for: name1) == .init(.a))
		#expect(KeyboardShortcuts.getShortcut(for: name2) == .init(.b))
		#expect(KeyboardShortcuts.getShortcut(for: name3) == nil)
	}
}

// MARK: - Modifier Symbol Tests

@Suite("Modifier Symbol Tests", .serialized)
struct ModifierSymbolTests {
	@Test("Individual modifier symbols")
	func testIndividualModifierSymbols() {
		#expect(NSEvent.ModifierFlags.control.ks_symbolicRepresentation == "⌃")
		#expect(NSEvent.ModifierFlags.option.ks_symbolicRepresentation == "⌥")
		#expect(NSEvent.ModifierFlags.shift.ks_symbolicRepresentation == "⇧")
		#expect(NSEvent.ModifierFlags.command.ks_symbolicRepresentation == "⌘")
		#expect(NSEvent.ModifierFlags([]).ks_symbolicRepresentation == "")
	}

	@Test("Combined modifier symbols")
	func testCombinedModifierSymbols() {
		// macOS standard order: Control, Option, Shift, Command
		// Two modifiers
		#expect(NSEvent.ModifierFlags([.control, .option]).ks_symbolicRepresentation == "⌃⌥")
		#expect(NSEvent.ModifierFlags([.command, .shift]).ks_symbolicRepresentation == "⇧⌘")
		#expect(NSEvent.ModifierFlags([.option, .command]).ks_symbolicRepresentation == "⌥⌘")

		// Three modifiers
		#expect(NSEvent.ModifierFlags([.control, .option, .shift]).ks_symbolicRepresentation == "⌃⌥⇧")
		#expect(NSEvent.ModifierFlags([.control, .shift, .command]).ks_symbolicRepresentation == "⌃⇧⌘")

		// All four main modifiers
		#expect(NSEvent.ModifierFlags([.control, .option, .shift, .command]).ks_symbolicRepresentation == "⌃⌥⇧⌘")
	}

	@Test("Modifier symbols via shortcut")
	func testModifierSymbolsViaShortcut() {
		let shortcut = KeyboardShortcuts.Shortcut(.a, modifiers: [.command, .shift])
		#expect(shortcut.modifiers.ks_symbolicRepresentation == "⇧⌘")

		let complexShortcut = KeyboardShortcuts.Shortcut(.space, modifiers: [.control, .option, .command])
		#expect(complexShortcut.modifiers.ks_symbolicRepresentation == "⌃⌥⌘")
	}

	@Test("Modifier order independence")
	func testModifierOrderIndependence() {
		// No matter the input order, output should be consistent
		#expect(NSEvent.ModifierFlags([.command, .shift, .option, .control]).ks_symbolicRepresentation == "⌃⌥⇧⌘")
		#expect(NSEvent.ModifierFlags([.shift, .control, .command, .option]).ks_symbolicRepresentation == "⌃⌥⇧⌘")
		#expect(NSEvent.ModifierFlags([.option, .command, .control, .shift]).ks_symbolicRepresentation == "⌃⌥⇧⌘")
	}

	@Test("Special modifiers and edge cases")
	func testSpecialModifiersAndEdgeCases() {
		// Function key modifier
		#expect(NSEvent.ModifierFlags.function.ks_symbolicRepresentation == "🌐︎")
		#expect(NSEvent.ModifierFlags([.function, .command]).ks_symbolicRepresentation == "⌘🌐︎")

		// All modifiers combined
		let allModifiers: NSEvent.ModifierFlags = [.control, .option, .shift, .command, .function]
		#expect(allModifiers.ks_symbolicRepresentation == "⌃⌥⇧⌘🌐︎")

		// Empty modifiers
		#expect(NSEvent.ModifierFlags().ks_symbolicRepresentation == "")
	}
}

// MARK: - UserDefaults Extension for Testing

extension UserDefaults {
	func removeAllKeyboardShortcuts() {
		dictionaryRepresentation().keys.forEach { key in
			if key.hasPrefix("KeyboardShortcuts_") {
				removeObject(forKey: key)
			}
		}
	}
}
