import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut1")
	static let testShortcut2 = Self("testShortcut2")
	static let testShortcut3 = Self("testShortcut3")
	static let testShortcut4 = Self("testShortcut4")
}

private struct DynamicShortcutRecorder: View {
	@Binding var name: KeyboardShortcuts.Name
	@Binding var isPressed: Bool

	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			KeyboardShortcuts.Recorder(for: name)
				.padding(.trailing, 10)
			Text("Pressed? \(isPressed ? "👍" : "👎")")
				.frame(width: 100, alignment: .leading)
		}
	}
}

private struct DynamicShortcut: View {
	private struct Shortcut: Hashable, Identifiable {
		var id: String
		var name: KeyboardShortcuts.Name
	}

	private static let shortcuts = [
		Shortcut(id: "Shortcut3", name: .testShortcut3),
		Shortcut(id: "Shortcut4", name: .testShortcut4)
	]

	@State private var shortcut = Self.shortcuts.first!
	@State private var isPressed = false

	var body: some View {
		VStack {
			Text("Dynamic Recorder")
				.bold()
				.padding(.bottom, 10)
			VStack {
				Picker("Select shortcut:", selection: $shortcut) {
					ForEach(Self.shortcuts) {
						Text($0.id)
							.tag($0)
					}
				}
				Divider()
				DynamicShortcutRecorder(name: $shortcut.name, isPressed: $isPressed)
			}
		}
			.frame(maxWidth: 300)
			.padding()
			.padding(.bottom, 20)
			.onChange(of: shortcut) { [oldValue = shortcut] in
				onShortcutChange(oldValue: oldValue, newValue: $0)
			}
	}

	private func onShortcutChange(oldValue: Shortcut, newValue: Shortcut) {
		KeyboardShortcuts.disable(oldValue.name)

		KeyboardShortcuts.onKeyDown(for: newValue.name) {
			isPressed = true
		}

		KeyboardShortcuts.onKeyUp(for: newValue.name) {
			isPressed = false
		}
	}
}

private struct DoubleShortcut: View {
	@State private var isPressed1 = false
	@State private var isPressed2 = false

	var body: some View {
		Form {
			KeyboardShortcuts.Recorder("Shortcut 1:", name: .testShortcut1)
				.overlay(alignment: .trailing) {
					Text("Pressed? \(isPressed1 ? "👍" : "👎")")
						.offset(x: 90)
				}
			KeyboardShortcuts.Recorder(for: .testShortcut2) {
				Text("Shortcut 2:") // Intentionally using the verbose initializer for testing.
			}
				.overlay(alignment: .trailing) {
					Text("Pressed? \(isPressed2 ? "👍" : "👎")")
						.offset(x: 90)
				}
			Spacer()
			Button("Reset All") {
				KeyboardShortcuts.reset(.testShortcut1, .testShortcut2)
			}
		}
			.offset(x: -40)
			.frame(maxWidth: 300)
			.padding()
			.padding()
			.task {
				KeyboardShortcuts.onKeyDown(for: .testShortcut1) {
					isPressed1 = true
				}

				KeyboardShortcuts.onKeyUp(for: .testShortcut1) {
					isPressed1 = false
				}

				KeyboardShortcuts.onKeyDown(for: .testShortcut2) {
					isPressed2 = true
				}

				KeyboardShortcuts.onKeyUp(for: .testShortcut2) {
					isPressed2 = false
				}
			}
	}
}

struct MainScreen: View {
	var body: some View {
		VStack {
			DoubleShortcut()
			Divider()
			DynamicShortcut()
		}
			.frame(width: 400, height: 320)
	}
}

struct MainScreen_Previews: PreviewProvider {
	static var previews: some View {
		MainScreen()
	}
}
