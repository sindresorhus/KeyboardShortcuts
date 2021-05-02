import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut1")
	static let testShortcut2 = Self("testShortcut2")
	static let testShortcut3 = Self("testShortcut3")
	static let testShortcut4 = Self("testShortcut4")
}

// TODO: Replace this with `View#onChange` when macOS 11 is out.
extension Binding {
	func onChange(_ handler: @escaping (Value, Value) -> Void) -> Binding<Value> {
		.init(
			get: {
				wrappedValue
			},
			set: {
				let oldValue = wrappedValue
				wrappedValue = $0
				handler(oldValue, wrappedValue)
			}
		)
	}
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

	@State private var shortcut = Self.shortcuts[0]
	@State private var isPressed = false

	var body: some View {
		VStack {
			Text("Dynamic Recorder")
				.bold()
				.padding(.bottom, 10)
			VStack {
				Picker("Select shortcut:", selection: $shortcut.onChange(onShortcutChange)) {
					ForEach(Self.shortcuts) {
						Text($0.id).tag($0)
					}
				}
				Divider()
				DynamicShortcutRecorder(name: $shortcut.name, isPressed: $isPressed)
			}
		}
			.frame(maxWidth: 300)
			.padding()
			.padding(.bottom, 20)
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
		VStack {
			HStack(alignment: .firstTextBaseline) {
				KeyboardShortcuts.Recorder(for: .testShortcut1)
					.padding(.trailing, 10)
				Text("Pressed? \(isPressed1 ? "👍" : "👎")")
					.frame(width: 100, alignment: .leading)
			}
			HStack(alignment: .firstTextBaseline) {
				KeyboardShortcuts.Recorder(for: .testShortcut2)
					.padding(.trailing, 10)
				Text("Pressed? \(isPressed2 ? "👍" : "👎")")
					.frame(width: 100, alignment: .leading)
			}
			Spacer()
			Divider()
			Button("Reset All") {
				KeyboardShortcuts.reset(.testShortcut1, .testShortcut2)
			}
		}
			.frame(maxWidth: 300)
			.padding()
			.padding()
			.onAppear {
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

struct ContentView: View {
	var body: some View {
		VStack {
			DoubleShortcut()
			Divider()
			DynamicShortcut()
		}
			.frame(width: 400, height: 320)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
