// Created by Neil Clayton on 17/07/2024.
// Using ideas by mbenoukaiss, https://github.com/sindresorhus/KeyboardShortcuts/issues/101


import Foundation
import SwiftUI
import Carbon

// Provides a SwiftUI like wrapper function, that feels the same as the normal SwiftUI .keyboardShortcut view extension
@available(macOS 12.3, *)
extension View {
	@MainActor
	public func keyboardShortcut(_ shortcutName: KeyboardShortcuts.Name) -> some View {
		KeyboardShortcutView(shortcutName: shortcutName) {
			self
		}
	}
}

@available(macOS 11.0, *)
extension KeyboardShortcuts.Shortcut {
	@MainActor
	var swiftKeyboardShortcut: KeyboardShortcut? {
		if let keyEquivalent = toKeyEquivalent() {
			return KeyboardShortcut(keyEquivalent, modifiers: toEventModifiers)
		}
		return nil
	}
}

// Holds the state of the shortcut, and changes that state when the shortcut changes
// This causes the related NSMenuItem to also update (yipeee)
@available(macOS 12.3, *)
@MainActor
struct KeyboardShortcutView<Content: View>: View {
	@State private var shortcutName: KeyboardShortcuts.Name
	@State private var shortcut: KeyboardShortcuts.Shortcut?

	private var content: () -> Content

	init(shortcutName: KeyboardShortcuts.Name, content: @escaping () -> Content) {
		self.shortcutName = shortcutName
		self.shortcut = KeyboardShortcuts.getShortcut(for: shortcutName)
		self.content = content
	}

	var shortcutBody: some View {
		content()
			.keyboardShortcut(shortcut?.swiftKeyboardShortcut)
	}

	var body: some View {
		shortcutBody
				// Called only when the shortcut is updated
				.onReceive(NotificationCenter.default.publisher(for: .shortcutByNameDidChange)) { notification in
					guard let name = notification.userInfo?["name"] as? KeyboardShortcuts.Name, name == shortcutName else {
						return
					}
					let current = KeyboardShortcuts.getShortcut(for: name)
					// this updates the shortcut state locally, refreshing the View, thus updating the SwiftUI menu item
					// It's also fine if it is nil (which happens when you set the shortcut, in RecorderCocoa).
					// See the comment on becomeFirstResponder (in short: so that you can reassign the SAME keypress to a shortcut, without it whining that it's already in use)
					shortcut = current
				}
	}
}

@available(macOS 11.0, *)
extension KeyboardShortcuts.Shortcut {
	@MainActor
	func toKeyEquivalent() -> KeyEquivalent? {
		guard let keyCharacter = keyToCharacter() else {
			return nil
		}
		return KeyEquivalent(Character(keyCharacter))
	}

	var toEventModifiers: SwiftUI.EventModifiers {
		var modifiers: SwiftUI.EventModifiers = []

		if self.modifiers.contains(NSEvent.ModifierFlags.command) {
			modifiers.insert(EventModifiers.command)
		}

		if self.modifiers.contains(NSEvent.ModifierFlags.control) {
			modifiers.insert(EventModifiers.control)
		}

		if self.modifiers.contains(NSEvent.ModifierFlags.option) {
			modifiers.insert(EventModifiers.option)
		}

		if self.modifiers.contains(NSEvent.ModifierFlags.shift) {
			modifiers.insert(EventModifiers.shift)
		}

		if self.modifiers.contains(NSEvent.ModifierFlags.capsLock) {
			modifiers.insert(EventModifiers.capsLock)
		}

		if self.modifiers.contains(NSEvent.ModifierFlags.numericPad) {
			modifiers.insert(EventModifiers.numericPad)
		}

		return modifiers
	}

}
