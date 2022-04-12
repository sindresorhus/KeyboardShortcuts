import SwiftUI

@available(macOS 12, *)
extension View {
	public func onShortcutEvent(_ shortcut: KeyboardShortcuts.Name, perform: @escaping (KeyboardShortcuts.EventType) -> Void) -> some View {
		let shortcutModifier = ShortcutViewModifier(shortcut: shortcut, perform: perform)
		return modifier(shortcutModifier)
	}

	public func onShortcutUp(_ shortcut: KeyboardShortcuts.Name, perform: @escaping () -> Void) -> some View {
		let shortcutModifier = ShortcutEventViewModifier(shortcut: shortcut, event: .keyUp, perform: perform)
		return modifier(shortcutModifier)
	}

	public func onShortcutDown(_ shortcut: KeyboardShortcuts.Name, perform: @escaping () -> Void) -> some View {
		let shortcutModifier = ShortcutEventViewModifier(shortcut: shortcut, event: .keyDown, perform: perform)
		return modifier(shortcutModifier)
	}
}

@available(macOS 12, *)
struct ShortcutEventViewModifier: ViewModifier {
	let shortcut: KeyboardShortcuts.Name
	let event: KeyboardShortcuts.EventType
	let perform: () -> Void

	func body(content: Content) -> some View {
		content
			.task {
				for await _ in KeyboardShortcuts.on(event, for: shortcut) {
					perform()
				}
			}
	}
}

@available(macOS 12, *)
struct ShortcutViewModifier: ViewModifier {
	let shortcut: KeyboardShortcuts.Name
	let perform: (KeyboardShortcuts.EventType) -> Void

	func body(content: Content) -> some View {
		content
			.task {
				for await _ in KeyboardShortcuts.on(.keyDown, for: shortcut) {
					perform(.keyDown)
				}
			}
			.task {
				for await _ in KeyboardShortcuts.on(.keyUp, for: shortcut) {
					perform(.keyUp)
				}
			}
	}
}
