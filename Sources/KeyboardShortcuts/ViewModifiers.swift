import SwiftUI

@available(macOS 12, *)
extension View {
	public func onKeyboardShortcut(_ shortcut: KeyboardShortcuts.Name, perform: @escaping (KeyboardShortcuts.EventType) -> Void) -> some View {
		task {
			for await event in KeyboardShortcuts.events(for: shortcut) {
				perform(event)
			}
		}
	}

	public func onKeyboardShortcut(_ shortcut: KeyboardShortcuts.Name, type: KeyboardShortcuts.EventType, perform: @escaping () -> Void) -> some View {
		task {
			for await _ in KeyboardShortcuts.events(for: shortcut, type: type) {
				perform()
			}
		}
	}
}
