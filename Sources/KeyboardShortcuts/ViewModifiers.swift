import SwiftUI

@available(macOS 12, *)
extension View {
	public func onKeyboardShortcut(_ shortcut: KeyboardShortcuts.Name, perform: @escaping (KeyboardShortcuts.EventType) -> Void) -> some View {
		self
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

	public func onKeyboardShortcut(_ shortcut: KeyboardShortcuts.Name, event: KeyboardShortcuts.EventType, perform: @escaping () -> Void) -> some View {
		self
			.task {
				for await _ in KeyboardShortcuts.on(event, for: shortcut) {
					perform()
				}
			}
	}
}
