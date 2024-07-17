// Created by Neil Clayton on 17/07/2024.
// Using ideas by mbenoukaiss, https://github.com/sindresorhus/KeyboardShortcuts/issues/101


import Foundation
import SwiftUI
import KeyboardShortcuts
import Carbon

// Provides a SwiftUI like wrapper func, that feels the same as the normal SwiftUI keyboardShortcut
@available(macOS 11.0, *)
extension View {
	@ViewBuilder
	public func keyboardShortcut(_ shortcutName: KeyboardShortcuts.Name) -> some View {
		KeyboardShortcutView(shortcutName: shortcutName) {
			self
		}
	}
}

// Holds the state of the shortcut, and changes that state when the shortcut changes
// This causes the related NSMenuItem to also update (yipeee)
@available(macOS 11.0, *)
struct KeyboardShortcutView<Content: View>: View {
	@State private var shortcutName: KeyboardShortcuts.Name
	@State private var shortcut: KeyboardShortcuts.Shortcut?

	private var content: () -> Content

	init(shortcutName: KeyboardShortcuts.Name, content: @escaping () -> Content) {
		self.shortcutName = shortcutName
		self.shortcut = KeyboardShortcuts.getShortcut(for: shortcutName)
		self.content = content
	}

	@ViewBuilder
	var shortcutBody: some View {
		if let shortcut, let keyEquivalent = shortcut.toKeyEquivalent() {
			content()
					.keyboardShortcut(keyEquivalent, modifiers: shortcut.toEventModifiers())
		} else {
			content()
		}
	}

	var body: some View {
		shortcutBody
				// Called only when the shortcut is updated
				.onReceive(NotificationCenter.default.publisher(for: .shortcutByNameDidChange)) { notification in
					if let name = notification.userInfo?["name"] as? KeyboardShortcuts.Name, name == shortcutName {
						let current = KeyboardShortcuts.getShortcut(for: name)
						// this updates the shortcut state locally, refreshing the View, thus updating the SwiftUI menu item
						// It's also fine if it is nil (which happens when you set the shortcut, in RecorderCocoa).
						// See the comment on becomeFirstResponder (in short: so that you can reassign the SAME keypress to a shortcut, without it whining that it's already in use)
						print("Shortcut \(shortcutName) updated to: \(current?.description ?? "nil")")
						shortcut = current
					}
				}
	}
}

@available(macOS 11.0, *)
extension KeyboardShortcuts.Shortcut {
	func toKeyEquivalent() -> KeyEquivalent? {
		let carbonKeyCode = UInt16(self.carbonKeyCode)
		let maxNameLength = 4
		var nameBuffer = [UniChar](repeating: 0, count: maxNameLength)
		var nameLength = 0

		let modifierKeys = UInt32(alphaLock >> 8) & 0xFF // Caps Lock
		var deadKeys: UInt32 = 0
		let keyboardType = UInt32(LMGetKbdType())

		let source = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
		guard let ptr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
			NSLog("Could not get keyboard layout data")
			return nil
		}
		let layoutData = Unmanaged<CFData>.fromOpaque(ptr).takeUnretainedValue() as Data
		let osStatus = layoutData.withUnsafeBytes {
			UCKeyTranslate($0.bindMemory(to: UCKeyboardLayout.self).baseAddress, carbonKeyCode, UInt16(kUCKeyActionDown),
					modifierKeys, keyboardType, UInt32(kUCKeyTranslateNoDeadKeysMask),
					&deadKeys, maxNameLength, &nameLength, &nameBuffer)
		}
		guard osStatus == noErr else {
			NSLog("Code: 0x%04X  Status: %+i", carbonKeyCode, osStatus);
			return nil
		}

		return KeyEquivalent(Character(String(utf16CodeUnits: nameBuffer, count: nameLength)))
	}

	func toEventModifiers() -> SwiftUI.EventModifiers {
		var modifiers: SwiftUI.EventModifiers = []

		if self.modifiers.contains(NSEvent.ModifierFlags.command) {
			modifiers.update(with: EventModifiers.command)
		}

		if self.modifiers.contains(NSEvent.ModifierFlags.control) {
			modifiers.update(with: EventModifiers.control)
		}

		if self.modifiers.contains(NSEvent.ModifierFlags.option) {
			modifiers.update(with: EventModifiers.option)
		}

		if self.modifiers.contains(NSEvent.ModifierFlags.shift) {
			modifiers.update(with: EventModifiers.shift)
		}

		if self.modifiers.contains(NSEvent.ModifierFlags.capsLock) {
			modifiers.update(with: EventModifiers.capsLock)
		}

		if self.modifiers.contains(NSEvent.ModifierFlags.numericPad) {
			modifiers.update(with: EventModifiers.numericPad)
		}

		return modifiers
	}

}
