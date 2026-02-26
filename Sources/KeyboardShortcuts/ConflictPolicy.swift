#if os(macOS)
import SwiftUI

extension KeyboardShortcuts {
	/**
	The behavior when a keyboard shortcut conflicts with an existing assignment.
	*/
	public enum ConflictBehavior: Equatable, Hashable, Sendable {
		/**
		Show a blocking alert. The shortcut is not saved.
		*/
		case block

		/**
		Show a “Use Anyway” confirmation dialog. The shortcut is saved only if the user confirms.
		*/
		case warn

		/**
		Silently allow the shortcut without any dialog.
		*/
		case allow
	}

	/**
	Controls how the recorder handles each category of keyboard shortcut conflict.
	*/
	public struct ConflictPolicy: Equatable, Hashable, Sendable {
		/**
		Behavior when the shortcut is already used by a menu item in the app's main menu.

		Default: `.block`
		*/
		public var menuItem: ConflictBehavior

		/**
		Behavior when the shortcut is already used by a system-level keyboard shortcut.

		Default: `.warn`
		*/
		public var systemShortcut: ConflictBehavior

		/**
		Behavior when the shortcut is disallowed by the system (e.g. sandboxed macOS 15+ restrictions).

		Default: `.block`. Note: `.warn` is treated the same as `.block` here — showing a “Use Anyway” dialog would be misleading since the shortcut will not work regardless of the user's choice.
		*/
		public var disallowed: ConflictBehavior

		public init(
			menuItem: ConflictBehavior = .block,
			systemShortcut: ConflictBehavior = .warn,
			disallowed: ConflictBehavior = .block
		) {
			self.menuItem = menuItem
			self.systemShortcut = systemShortcut
			self.disallowed = disallowed
		}

		/**
		The default conflict policy, matching the framework's built-in behavior.
		*/
		public static let `default` = Self()

		/**
		A policy that silently allows all shortcuts regardless of conflicts.

		- Important: Only use this if you use completely custom validation with ``Recorder/shortcutValidation(_:)``.
		*/
		public static let allowAll = Self(
			menuItem: .allow,
			systemShortcut: .allow,
			disallowed: .allow
		)
	}
}

extension EnvironmentValues {
	@Entry
	var keyboardShortcutsConflictPolicy = KeyboardShortcuts.ConflictPolicy.default
}

extension View {
	/**
	Controls how all `KeyboardShortcuts.Recorder` views in this view hierarchy handle keyboard shortcut conflicts.

	```swift
	// Warn on menu item conflicts, keep other defaults.
	Form {
		KeyboardShortcuts.Recorder("Toggle Unicorn Mode:", name: .toggleUnicornMode)
	}
	.keyboardShortcutsConflictPolicy(.init(menuItem: .warn))
	```
	*/
	public func keyboardShortcutsConflictPolicy(_ policy: KeyboardShortcuts.ConflictPolicy) -> some View {
		environment(\.keyboardShortcutsConflictPolicy, policy)
	}
}
#endif
