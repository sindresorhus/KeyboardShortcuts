import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut1")
	static let testShortcut2 = Self("testShortcut2")
	static let testShortcut3 = Self("testShortcut3")
	static let testShortcut4 = Self("testShortcut4")
}

private struct MultiChordRecorder: View {
    @State private var sequence: ShortcutSequence = .init([])

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Multi-chord Recorder")
                .bold()
            Text("Recorded:")
            Text(sequence.presentableDescription.isEmpty ? "-" : sequence.presentableDescription)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
            ShortcutRecordView(
                sequence: $sequence,
                option: .init(enableSequences: true, maxSequenceLength: 2)
            )
        }
        .frame(maxWidth: 300)
        .padding()
    }
}

private struct DynamicShortcutRecorder: View {
	@FocusState private var isFocused: Bool

	@Binding var name: KeyboardShortcuts.Name
	@Binding var isPressed: Bool

	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			KeyboardShortcuts.Recorder(for: name)
				.focused($isFocused)
				.padding(.trailing, 10)
			Text("Pressed? \(isPressed ? "👍" : "👎")")
				.frame(width: 100, alignment: .leading)
		}
		.onChange(of: name) {
			isFocused = true
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
			Divider()
				.padding(.vertical)
			Button("Reset All") {
				KeyboardShortcuts.resetAll()
			}
		}
		.frame(maxWidth: 300)
		.padding()
		.padding(.bottom, 20)
		.onChange(of: shortcut, initial: true) { oldValue, newValue in
			onShortcutChange(oldValue: oldValue, newValue: newValue)
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
		}
		.offset(x: -40)
		.frame(maxWidth: 300)
		.padding()
		.padding()
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

struct MainScreen: View {
    var body: some View {
        VStack {
            DoubleShortcut()
            Divider()
            DynamicShortcut()
            Divider()
            MultiChordRecorder()
        }
        .frame(width: 400, height: 400)
    }
}

#Preview {
	MainScreen()
}
