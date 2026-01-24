import Testing
import Foundation
import AppKit
import Carbon.HIToolbox
@testable import KeyboardShortcuts

@Suite("KeyboardShortcuts Tests", .serialized)
struct KeyboardShortcutsTests {
	init() {
		UserDefaults.standard.removeAllKeyboardShortcuts()
	}

	/**
	Returns whether a Carbon hotkey can be registered for the given shortcut.
	*/
	private static func canRegisterHotKey(for shortcut: KeyboardShortcuts.Shortcut) -> Bool {
		HotKey(
			carbonKeyCode: shortcut.carbonKeyCode,
			carbonModifiers: shortcut.carbonModifiers,
			onKeyDown: {},
			onKeyUp: {}
		) != nil
	}

	/**
	Waits until the condition returns `true` or the timeout is reached.
	*/
	private static func waitUntilConditionIsTrue(
		timeout: Duration = .seconds(1),
		condition: @escaping @Sendable @MainActor () -> Bool
	) async -> Bool {
		let clock = ContinuousClock()
		let deadline = clock.now + timeout

		while !(await MainActor.run(body: condition)) {
			guard clock.now < deadline else {
				return false
			}

			try? await Task.sleep(for: .milliseconds(10))
		}

		return true
	}

	/**
	Returns whether the shared hotkey center is in normal mode.
	*/
	private static func hotKeyCenterIsInNormalMode() -> Bool {
		if case .normal = HotKeyCenter.shared.mode {
			return true
		}

		return false
	}

	/**
	Returns whether the shared hotkey center is in menu-open mode.
	*/
	private static func hotKeyCenterIsInMenuOpenMode() -> Bool {
		if case .menuOpen = HotKeyCenter.shared.mode {
			return true
		}

		return false
	}

	/**
	Returns whether the shared hotkey center is in disabled mode.
	*/
	private static func hotKeyCenterIsInDisabledMode() -> Bool {
		if case .disabled = HotKeyCenter.shared.mode {
			return true
		}

		return false
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

	@Test("Reset all clears defaults")
	func testResetAllClearsDefaults() {
		let nameWithDefault = KeyboardShortcuts.Name("resetAllDefault", default: .init(.a))
		let nameWithoutDefault = KeyboardShortcuts.Name("resetAllNoDefault")

		KeyboardShortcuts.setShortcut(.init(.b), for: nameWithDefault)
		KeyboardShortcuts.setShortcut(.init(.c), for: nameWithoutDefault)

		KeyboardShortcuts.resetAll()

		#expect(KeyboardShortcuts.getShortcut(for: nameWithDefault) == nil)
		#expect(KeyboardShortcuts.getShortcut(for: nameWithoutDefault) == nil)
	}

	@Test("Removing shortcut clears disabled marker for names without default")
	func testRemovingShortcutClearsDisabledMarkerForNamesWithoutDefault() {
		let shortcutKey = "KeyboardShortcuts_removeDisabledDefault"
		let nameWithDefault = KeyboardShortcuts.Name("removeDisabledDefault", default: .init(.a))

		KeyboardShortcuts.setShortcut(nil, for: nameWithDefault)
		#expect(UserDefaults.standard.object(forKey: shortcutKey) as? Bool == false)

		let nameWithoutDefault = KeyboardShortcuts.Name("removeDisabledDefault")
		KeyboardShortcuts.setShortcut(nil, for: nameWithoutDefault)

		#expect(UserDefaults.standard.object(forKey: shortcutKey) == nil)
	}

	@Test("Disable one name does not affect another with same shortcut")
	func testDisableWithSharedShortcut() throws {
		let shortcut = KeyboardShortcuts.Shortcut(.n, modifiers: [.command])
		let name1 = KeyboardShortcuts.Name("shared1", default: shortcut)
		let name2 = KeyboardShortcuts.Name("shared2", default: shortcut)

		KeyboardShortcuts.onKeyDown(for: name1) {}
		KeyboardShortcuts.onKeyDown(for: name2) {}

		#expect(KeyboardShortcuts.isEnabled(for: name1))
		#expect(KeyboardShortcuts.isEnabled(for: name2))

		KeyboardShortcuts.disable(name1)
		#expect(!KeyboardShortcuts.isEnabled(for: name1))
		#expect(KeyboardShortcuts.isEnabled(for: name2))

		KeyboardShortcuts.enable(name1)
		KeyboardShortcuts.disable(name2)
		#expect(KeyboardShortcuts.isEnabled(for: name1))
		#expect(!KeyboardShortcuts.isEnabled(for: name2))

		KeyboardShortcuts.removeAllHandlers()
	}

	@Test("IsEnabled requires active handlers")
	func testIsEnabledRequiresActiveHandlers() {
		let shortcut = KeyboardShortcuts.Shortcut(.l, modifiers: [.command, .option, .shift, .control])
		let name = KeyboardShortcuts.Name("enabledRequiresHandlers", default: shortcut)

		#expect(!KeyboardShortcuts.isEnabled(for: name))

		KeyboardShortcuts.onKeyDown(for: name) {}
		#expect(KeyboardShortcuts.isEnabled(for: name))

		KeyboardShortcuts.removeHandler(for: name)
		#expect(!KeyboardShortcuts.isEnabled(for: name))
	}

	@Test("Disabling a name unregisters its hotkey")
	func testDisableUnregistersHotKey() {
		let shortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .option, .shift, .control])
		let name = KeyboardShortcuts.Name("disableUnregister", default: shortcut)

		KeyboardShortcuts.onKeyDown(for: name) {}
		#expect(KeyboardShortcuts.isEnabled(for: name))

		KeyboardShortcuts.disable(name)
		#expect(!KeyboardShortcuts.isEnabled(for: name))

		#expect(Self.canRegisterHotKey(for: shortcut))

		KeyboardShortcuts.removeAllHandlers()
	}

	@Test("Resume failure drops hotkey registration")
	func testResumeFailureDropsHotKeyRegistration() async {
		let shortcut = KeyboardShortcuts.Shortcut(.f14, modifiers: [.command, .option, .shift, .control])
		let name = KeyboardShortcuts.Name("resumeFailureDropsHotKey", default: shortcut)
		let wasEnabled = KeyboardShortcuts.isEnabled
		let testSignature: UInt32 = 0x54455354
		var competingEventHotKey: EventHotKeyRef?

		defer {
			KeyboardShortcuts.isEnabled = wasEnabled
			if let competingEventHotKey {
				UnregisterEventHotKey(competingEventHotKey)
			}
			KeyboardShortcuts.removeAllHandlers()
		}

		KeyboardShortcuts.isEnabled = true
		KeyboardShortcuts.onKeyDown(for: name) {}
		#expect(KeyboardShortcuts.isEnabled(for: name))

		KeyboardShortcuts.isEnabled = false
		#expect(await Self.waitUntilConditionIsTrue {
			Self.canRegisterHotKey(for: shortcut)
		})

		let error = RegisterEventHotKey(
			UInt32(shortcut.carbonKeyCode),
			UInt32(shortcut.carbonModifiers),
			EventHotKeyID(signature: testSignature, id: 1),
			GetEventDispatcherTarget(),
			0,
			&competingEventHotKey
		)

		#expect(error == noErr)
		#expect(competingEventHotKey != nil)

		KeyboardShortcuts.isEnabled = true
		#expect(await Self.waitUntilConditionIsTrue {
			!KeyboardShortcuts.isEnabled(for: name)
		})
	}

	@Test("Disabled names do not keep shortcuts registered")
	func testDisabledNamesDoNotKeepShortcutsRegistered() {
		let shortcut = KeyboardShortcuts.Shortcut(.j, modifiers: [.command, .option, .shift, .control])
		let name1 = KeyboardShortcuts.Name("disableShared1", default: shortcut)
		let name2 = KeyboardShortcuts.Name("disableShared2", default: shortcut)

		KeyboardShortcuts.onKeyDown(for: name1) {}
		KeyboardShortcuts.onKeyDown(for: name2) {}

		KeyboardShortcuts.disable(name1)
		KeyboardShortcuts.removeHandler(for: name2)

		#expect(Self.canRegisterHotKey(for: shortcut))

		KeyboardShortcuts.removeAllHandlers()
	}

	@Test("Menu tracking notifications switch hotkey mode")
	func testMenuTrackingNotificationsSwitchHotKeyMode() async {
		let wasEnabled = KeyboardShortcuts.isEnabled

		defer {
			NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: nil)
			KeyboardShortcuts.isEnabled = wasEnabled
		}

		KeyboardShortcuts.isEnabled = true
		NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: nil)
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInNormalMode()
		})

		NotificationCenter.default.post(name: NSMenu.didBeginTrackingNotification, object: nil)
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInMenuOpenMode()
		})

		NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: nil)
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInNormalMode()
		})
	}

	@Test("HotKeyCenter menu observers respond to notifications")
	func testHotKeyCenterMenuObserversRespondToNotifications() async {
		let wasEnabled = KeyboardShortcuts.isEnabled

		defer {
			NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: nil)
			KeyboardShortcuts.isEnabled = wasEnabled
		}

		KeyboardShortcuts.isEnabled = true
		let _ = HotKeyCenter.shared

		NotificationCenter.default.post(name: NSMenu.didBeginTrackingNotification, object: nil)
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInMenuOpenMode()
		})

		NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: nil)
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInNormalMode()
		})
	}

	@Test("Menu tracking notifications from detached tasks are handled")
	func testMenuTrackingNotificationsFromDetachedTasksAreHandled() async {
		let wasEnabled = KeyboardShortcuts.isEnabled

		defer {
			NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: nil)
			KeyboardShortcuts.isEnabled = wasEnabled
		}

		KeyboardShortcuts.isEnabled = true
		let _ = HotKeyCenter.shared

		await Task.detached {
			NotificationCenter.default.post(name: NSMenu.didBeginTrackingNotification, object: nil)
		}.value

		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInMenuOpenMode()
		})

		await Task.detached {
			NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: nil)
		}.value

		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInNormalMode()
		})
	}

	@Test("Menu tracking notifications keep disabled mode when globally disabled")
	func testMenuTrackingNotificationsRespectGlobalDisable() async {
		let wasEnabled = KeyboardShortcuts.isEnabled

		defer {
			NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: nil)
			KeyboardShortcuts.isEnabled = wasEnabled
		}

		KeyboardShortcuts.isEnabled = false
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInDisabledMode()
		})

		NotificationCenter.default.post(name: NSMenu.didBeginTrackingNotification, object: nil)
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInDisabledMode()
		})

		NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: nil)
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInDisabledMode()
		})
	}

	@Test("Enabling while menu is open enters menu-open mode")
	func testEnablingWhileMenuIsOpenEntersMenuOpenMode() async {
		let wasEnabled = KeyboardShortcuts.isEnabled

		defer {
			NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: nil)
			KeyboardShortcuts.isEnabled = wasEnabled
		}

		KeyboardShortcuts.isEnabled = false
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInDisabledMode()
		})

		NotificationCenter.default.post(name: NSMenu.didBeginTrackingNotification, object: nil)
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInDisabledMode()
		})

		KeyboardShortcuts.isEnabled = true
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInMenuOpenMode()
		})

		NotificationCenter.default.post(name: NSMenu.didEndTrackingNotification, object: nil)
		#expect(await Self.waitUntilConditionIsTrue {
			Self.hotKeyCenterIsInNormalMode()
		})
	}

	@Test("Disabling and enabling works with stream-only handlers")
	func testDisableAndEnableWithStreamOnlyHandlers() async {
		let shortcut = KeyboardShortcuts.Shortcut(.f12, modifiers: [.command, .option, .shift, .control])
		let name = KeyboardShortcuts.Name("streamDisableEnable", default: shortcut)
		var stream: AsyncStream<KeyboardShortcuts.EventType>? = KeyboardShortcuts.events(for: name)
		var iterator: AsyncStream<KeyboardShortcuts.EventType>.AsyncIterator? = stream?.makeAsyncIterator()
		var waitingForEventTask: Task<Void, Never>? = Task {
			_ = await iterator?.next()
		}
		#expect(iterator != nil)

		defer {
			waitingForEventTask?.cancel()
		}

		#expect(await Self.waitUntilConditionIsTrue {
			KeyboardShortcuts.isEnabled(for: name)
		})
		#expect(!Self.canRegisterHotKey(for: shortcut))

		KeyboardShortcuts.disable(name)
		#expect(!KeyboardShortcuts.isEnabled(for: name))
		#expect(Self.canRegisterHotKey(for: shortcut))

		KeyboardShortcuts.enable(name)
		#expect(await Self.waitUntilConditionIsTrue {
			KeyboardShortcuts.isEnabled(for: name)
		})
		#expect(!Self.canRegisterHotKey(for: shortcut))

		iterator = nil
		stream = nil
		waitingForEventTask?.cancel()
		waitingForEventTask = nil

		#expect(await Self.waitUntilConditionIsTrue {
			Self.canRegisterHotKey(for: shortcut)
		})
	}

	@Test("Updating shortcut while disabled defers registration")
	func testUpdatingShortcutWhileDisabledDefersRegistration() {
		let originalShortcut = KeyboardShortcuts.Shortcut(.f20, modifiers: [.command, .option, .shift, .control])
		let updatedShortcut = KeyboardShortcuts.Shortcut(.f19, modifiers: [.command, .option, .shift, .control])
		let name = KeyboardShortcuts.Name("setWhileDisabled", default: originalShortcut)

		KeyboardShortcuts.onKeyDown(for: name) {}

		defer {
			KeyboardShortcuts.enable(name)
			KeyboardShortcuts.removeAllHandlers()
		}

		#expect(KeyboardShortcuts.isEnabled(for: name))

		KeyboardShortcuts.disable(name)
		#expect(Self.canRegisterHotKey(for: originalShortcut))

		KeyboardShortcuts.setShortcut(updatedShortcut, for: name)
		#expect(KeyboardShortcuts.getShortcut(for: name) == updatedShortcut)
		#expect(Self.canRegisterHotKey(for: updatedShortcut))

		KeyboardShortcuts.enable(name)
		#expect(KeyboardShortcuts.isEnabled(for: name))
		#expect(!Self.canRegisterHotKey(for: updatedShortcut))
	}

	@Test("Shortcut recovers after resume conflict when reapplied")
	func testShortcutRecoversAfterResumeConflictWhenReapplied() async {
		let shortcut = KeyboardShortcuts.Shortcut(.f13, modifiers: [.command, .option, .shift, .control])
		let name = KeyboardShortcuts.Name("resumeConflictRecovery", default: shortcut)
		let wasEnabled = KeyboardShortcuts.isEnabled
		let testSignature: UInt32 = 0x54455354
		var competingEventHotKey: EventHotKeyRef?

		defer {
			KeyboardShortcuts.isEnabled = wasEnabled
			if let competingEventHotKey {
				UnregisterEventHotKey(competingEventHotKey)
			}
			KeyboardShortcuts.removeAllHandlers()
		}

		KeyboardShortcuts.isEnabled = true
		KeyboardShortcuts.onKeyDown(for: name) {}
		#expect(KeyboardShortcuts.isEnabled(for: name))

		KeyboardShortcuts.isEnabled = false
		#expect(await Self.waitUntilConditionIsTrue {
			Self.canRegisterHotKey(for: shortcut)
		})

		let error = RegisterEventHotKey(
			UInt32(shortcut.carbonKeyCode),
			UInt32(shortcut.carbonModifiers),
			EventHotKeyID(signature: testSignature, id: 2),
			GetEventDispatcherTarget(),
			0,
			&competingEventHotKey
		)

		#expect(error == noErr)
		#expect(competingEventHotKey != nil)

		KeyboardShortcuts.isEnabled = true
		#expect(await Self.waitUntilConditionIsTrue {
			!KeyboardShortcuts.isEnabled(for: name)
		})

		UnregisterEventHotKey(competingEventHotKey)
		competingEventHotKey = nil

		KeyboardShortcuts.setShortcut(shortcut, for: name)
		#expect(KeyboardShortcuts.isEnabled(for: name))
	}

	@Test("Stream handlers keep shortcuts registered when removing legacy handlers")
	func testStreamHandlersKeepShortcutsRegisteredWhenRemovingLegacyHandlers() async {
		let shortcut = KeyboardShortcuts.Shortcut(.f19, modifiers: [.command, .option, .shift, .control])
		let name = KeyboardShortcuts.Name("streamKeepsRegistered", default: shortcut)

		var stream: AsyncStream<KeyboardShortcuts.EventType>? = KeyboardShortcuts.events(for: name)
		var iterator: AsyncStream<KeyboardShortcuts.EventType>.AsyncIterator? = stream?.makeAsyncIterator()
		#expect(iterator != nil)

		#expect(await Self.waitUntilConditionIsTrue {
			KeyboardShortcuts.isEnabled(for: name)
		})

		KeyboardShortcuts.removeHandler(for: name)

		#expect(KeyboardShortcuts.isEnabled(for: name))

		iterator = nil
		stream = nil

		#expect(await Self.waitUntilConditionIsTrue {
			Self.canRegisterHotKey(for: shortcut)
		})
	}

	@Test("Ending stream does not unregister when legacy handlers remain")
	func testStreamEndingDoesNotUnregisterWhenLegacyHandlersRemain() async {
		let shortcut = KeyboardShortcuts.Shortcut(.f16, modifiers: [.command, .option, .shift, .control])
		let name = KeyboardShortcuts.Name("streamEndingKeepsLegacyHandlers", default: shortcut)

		KeyboardShortcuts.onKeyDown(for: name) {}

		var stream: AsyncStream<KeyboardShortcuts.EventType>? = KeyboardShortcuts.events(for: name)
		var iterator: AsyncStream<KeyboardShortcuts.EventType>.AsyncIterator? = stream?.makeAsyncIterator()
		#expect(iterator != nil)

		#expect(await Self.waitUntilConditionIsTrue {
			!Self.canRegisterHotKey(for: shortcut)
		})

		iterator = nil
		stream = nil

		#expect(await Self.waitUntilConditionIsTrue {
			KeyboardShortcuts.isEnabled(for: name)
		})

		#expect(KeyboardShortcuts.isEnabled(for: name))
		#expect(!Self.canRegisterHotKey(for: shortcut))

		KeyboardShortcuts.removeHandler(for: name)
	}

	@Test("Stream handlers release old shortcuts when changing shortcuts")
	func testStreamHandlersReleaseOldShortcutsWhenChangingShortcuts() async {
		let originalShortcut = KeyboardShortcuts.Shortcut(.f18, modifiers: [.command, .option, .shift, .control])
		let updatedShortcut = KeyboardShortcuts.Shortcut(.f17, modifiers: [.command, .option, .shift, .control])
		let name = KeyboardShortcuts.Name("streamUpdatesShortcut", default: originalShortcut)

		var stream: AsyncStream<KeyboardShortcuts.EventType>? = KeyboardShortcuts.events(for: name)
		var iterator: AsyncStream<KeyboardShortcuts.EventType>.AsyncIterator? = stream?.makeAsyncIterator()
		#expect(iterator != nil)

		#expect(await Self.waitUntilConditionIsTrue {
			KeyboardShortcuts.isEnabled(for: name)
		})

		KeyboardShortcuts.setShortcut(updatedShortcut, for: name)

		#expect(await Self.waitUntilConditionIsTrue {
			Self.canRegisterHotKey(for: originalShortcut)
		})

		iterator = nil
		stream = nil

		#expect(await Self.waitUntilConditionIsTrue {
			Self.canRegisterHotKey(for: updatedShortcut)
		})
	}

	@Test("Shortcut can be re-registered after clearing")
	func testShortcutReregistration() throws {
		let shortcut = KeyboardShortcuts.Shortcut(.m, modifiers: [.command])
		let name = KeyboardShortcuts.Name("reregisterTest")

		// Set shortcut
		KeyboardShortcuts.setShortcut(shortcut, for: name)
		#expect(KeyboardShortcuts.getShortcut(for: name) == shortcut)

		// Clear shortcut
		KeyboardShortcuts.setShortcut(nil, for: name)
		#expect(KeyboardShortcuts.getShortcut(for: name) == nil)

		// Re-register the same shortcut
		KeyboardShortcuts.setShortcut(shortcut, for: name)
		#expect(KeyboardShortcuts.getShortcut(for: name) == shortcut)
	}

	@Test("Changing shortcut releases old and registers new")
	func testChangingShortcutUpdatesRegistration() {
		let shortcutA = KeyboardShortcuts.Shortcut(.f16, modifiers: [.command, .option, .shift, .control])
		let shortcutB = KeyboardShortcuts.Shortcut(.f15, modifiers: [.command, .option, .shift, .control])
		let name = KeyboardShortcuts.Name("changeShortcutTest", default: shortcutA)

		KeyboardShortcuts.onKeyDown(for: name) {}
		#expect(KeyboardShortcuts.isEnabled(for: name))

		KeyboardShortcuts.setShortcut(shortcutB, for: name)

		// Old shortcut should be released
		#expect(Self.canRegisterHotKey(for: shortcutA))

		// New shortcut should be registered
		#expect(KeyboardShortcuts.isEnabled(for: name))
		#expect(KeyboardShortcuts.getShortcut(for: name) == shortcutB)

		KeyboardShortcuts.removeAllHandlers()
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
	/**
	Removes all stored keyboard shortcuts from user defaults.
	*/
	func removeAllKeyboardShortcuts() {
		for key in dictionaryRepresentation().keys {
			if key.hasPrefix("KeyboardShortcuts_") {
				removeObject(forKey: key)
			}
		}
	}
}
