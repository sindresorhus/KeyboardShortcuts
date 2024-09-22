#if os(macOS)
import SwiftUI

@available(macOS 12, *)
extension View {
	/**
	Renamed to `onGlobalKeyboardShortcut`.
	*/
	@available(*, deprecated, renamed: "onGlobalKeyboardShortcut")
	public func onKeyboardShortcut(
		_ shortcut: KeyboardShortcuts.Name,
		perform: @escaping (KeyboardShortcuts.EventType) -> Void
	) -> some View {
		task {
			for await eventType in KeyboardShortcuts.events(for: shortcut) {
				perform(eventType)
			}
		}
	}

	/**
	Renamed to `onGlobalKeyboardShortcut`.
	*/
	@available(*, deprecated, renamed: "onGlobalKeyboardShortcut")
	public func onKeyboardShortcut(
		_ shortcut: KeyboardShortcuts.Name,
		type: KeyboardShortcuts.EventType,
		perform: @escaping () -> Void
	) -> some View {
		task {
			for await _ in KeyboardShortcuts.events(type, for: shortcut) {
				perform()
			}
		}
	}
}

@available(macOS 12, *)
extension View {
	/**
	Register a listener for keyboard shortcut events with the given name.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	The listener will stop automatically when the view disappears.

	- Note: This method is not affected by `.removeAllHandlers()`.
	*/
	public func onGlobalKeyboardShortcut(
		_ shortcut: KeyboardShortcuts.Name,
		perform: @escaping (KeyboardShortcuts.EventType) -> Void
	) -> some View {
		task {
			for await eventType in KeyboardShortcuts.events(for: shortcut) {
				perform(eventType)
			}
		}
	}

	/**
	Register a listener for keyboard shortcut events with the given name and type.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	The listener will stop automatically when the view disappears.

	- Note: This method is not affected by `.removeAllHandlers()`.
	*/
	public func onGlobalKeyboardShortcut(
		_ shortcut: KeyboardShortcuts.Name,
		type: KeyboardShortcuts.EventType,
		perform: @escaping () -> Void
	) -> some View {
		task {
			for await _ in KeyboardShortcuts.events(type, for: shortcut) {
				perform()
			}
		}
	}
}

@available(macOS 12.3, *)
extension View {
	/**
	Associates a global keyboard shortcut with a control.

	This is mostly useful to have the keyboard shortcut show for a `Button` in a `Menu` or `MenuBarExtra`.

	It does not trigger the control's action.

	- Important: Do not use it in a `CommandGroup` as the shortcut recorder will think the shortcut is already taken. It does remove the shortcut while the recorder is active, but because of a bug in macOS 15, the state is not reflected correctly in the underlying menu item.
	*/
	public func globalKeyboardShortcut(_ name: KeyboardShortcuts.Name) -> some View {
		modifier(GlobalKeyboardShortcutViewModifier(name: name))
	}
}

@available(macOS 12.3, *)
private struct GlobalKeyboardShortcutViewModifier: ViewModifier {
	@State private var isRecorderActive = false
	@State private var triggerRefresh = false

	let name: KeyboardShortcuts.Name

	func body(content: Content) -> some View {
		content
			.keyboardShortcut(isRecorderActive ? nil : name.shortcut?.toSwiftUI)
			.id(triggerRefresh)
			.onReceive(NotificationCenter.default.publisher(for: .shortcutByNameDidChange)) {
				guard $0.userInfo?["name"] as? KeyboardShortcuts.Name == name else {
					return
				}

				triggerRefresh.toggle()
			}
			.onReceive(NotificationCenter.default.publisher(for: .recorderActiveStatusDidChange)) {
				isRecorderActive = $0.userInfo?["isActive"] as? Bool ?? false
			}
	}
}
#endif
