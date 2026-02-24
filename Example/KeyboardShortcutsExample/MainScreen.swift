import SwiftUI
import KeyboardShortcuts

struct MainScreen: View {
	var body: some View {
		Form {
			Section("Fixed Shortcuts") {
				DoubleShortcut()
			}
			Section("Binding Shortcut") {
				BindingShortcut()
			}
			Section("Dynamic Shortcut") {
				DynamicShortcut()
			}
		}
		.formStyle(.grouped)
		.fixedSize()
	}
}

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut1")
	static let testShortcut2 = Self("testShortcut2")
	static let testShortcut3 = Self("testShortcut3")
	static let testShortcut4 = Self("testShortcut4")
}

private struct DoubleShortcut: View {
	@State private var isPressed1 = false
	@State private var isPressed2 = false

	var body: some View {
		LabeledContent("Shortcut 1") {
			KeyboardShortcuts.Recorder(for: .testShortcut1)
			// Uncomment to test.
			//	.shortcutValidation {
			//		$0 == .init(.k, modifiers: .command) ? .disallow(reason: "⌘K is not allowed.") : .allow
			// }
			Text(isPressed1 ? "👍" : "👎")
				.bold()
				.foregroundStyle(isPressed1 ? .green : .red)
		}
		LabeledContent("Shortcut 2") {
			KeyboardShortcuts.Recorder(for: .testShortcut2)
			Text(isPressed2 ? "👍" : "👎")
				.bold()
				.foregroundStyle(isPressed2 ? .green : .red)
		}
		.onGlobalKeyboardShortcut(.testShortcut1) {
			isPressed1 = $0 == .keyDown
		}
		.onGlobalKeyboardShortcut(.testShortcut2, type: .keyDown) {
			isPressed2 = true
		}
		.task {
			KeyboardShortcuts.onKeyUp(for: .testShortcut2) {
				isPressed2 = false
			}
		}
	}
}

private struct BindingShortcut: View {
	@State private var shortcut: KeyboardShortcuts.Shortcut?

	var body: some View {
		KeyboardShortcuts.Recorder("Shortcut", shortcut: $shortcut)
		HStack {
			Text(shortcut.map { "\($0.description)" } ?? "None")
				.foregroundStyle(.secondary)
			Spacer()
			Button("Clear") {
				shortcut = nil
			}
		}
	}
}

private struct DynamicShortcut: View {
	private struct Shortcut: Hashable, Identifiable {
		var id: String
		var name: KeyboardShortcuts.Name
	}

	private static let shortcuts = [
		Shortcut(id: "Shortcut 3", name: .testShortcut3),
		Shortcut(id: "Shortcut 4", name: .testShortcut4)
	]

	@State private var shortcut = Self.shortcuts.first!
	@State private var isPressed = false

	var body: some View {
		LabeledContent("Shortcut") {
			VStack(alignment: .trailing) {
				Picker("Shortcut", selection: $shortcut) {
					ForEach(Self.shortcuts) {
						Text($0.id)
							.tag($0)
					}
				}
				.labelsHidden()
				DynamicShortcutRecorder(name: $shortcut.name, isPressed: $isPressed)
					.labelsHidden()
				Button("Reset All") {
					KeyboardShortcuts.resetAll()
				}
				.frame(maxWidth: .infinity, alignment: .trailing)
			}
		}
		.onChange(of: shortcut, initial: true) { oldValue, newValue in
			onShortcutChange(oldValue: oldValue, newValue: newValue)
		}
	}

	private func onShortcutChange(oldValue: Shortcut, newValue: Shortcut) {
		if oldValue != newValue {
			KeyboardShortcuts.removeHandler(for: oldValue.name)
		}

		KeyboardShortcuts.onKeyDown(for: newValue.name) {
			isPressed = true
		}

		KeyboardShortcuts.onKeyUp(for: newValue.name) {
			isPressed = false
		}
	}
}

private struct DynamicShortcutRecorder: View {
	@FocusState private var isFocused: Bool

	@Binding var name: KeyboardShortcuts.Name
	@Binding var isPressed: Bool

	var body: some View {
		HStack {
			KeyboardShortcuts.Recorder(for: name)
				.labelsHidden()
				.focused($isFocused)
			Text(isPressed ? "👍" : "👎")
				.bold()
				.foregroundStyle(isPressed ? .green : .red)
		}
		.onChange(of: name) { _, _ in
			isFocused = true
		}
	}
}
