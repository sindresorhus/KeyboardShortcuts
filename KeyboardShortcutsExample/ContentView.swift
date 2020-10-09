import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut1")
	static let testShortcut2 = Self("testShortcut2")
	static let testShortcut3 = Self("testShortcut3")
	static let testShortcut4 = Self("testShortcut4")
}

extension Binding {
	func onChange(_ handler: @escaping (Value, Value) -> Void) -> Binding<Value> {
				Binding(
						get: { [self] in
							wrappedValue
						},
						set: { [self] selection in
								let oldValue = wrappedValue
								wrappedValue = selection
								handler(oldValue, wrappedValue)
						}
				)
		}
}

struct Shortcut: Identifiable, Hashable {
	var id: String
	var name: KeyboardShortcuts.Name
}

let shortcuts = [
	Shortcut(id: "Shortcut3", name: .testShortcut3),
	Shortcut(id: "Shortcut4", name: .testShortcut4)
]

struct DynamicShortcutRecorder: View {
	@Binding var name: KeyboardShortcuts.Name
	@Binding var isPressed: Bool

	var body: some View {
		HStack {
			KeyboardShortcuts.Recorder(for: name)
				.padding(.trailing, 10)
			Text("Pressed? \(isPressed ? "👍" : "👎")")
				.frame(width: 100, alignment: .leading)
		}
	}
}

struct DynamicShortcut: View {
	@State private var shortcut: Shortcut = shortcuts[0]
	@State private var isPressed: Bool = false

	func onShortcutChange(oldValue: Shortcut, newValue: Shortcut) {
		KeyboardShortcuts.disable(oldValue.name)

		KeyboardShortcuts.onKeyDown(for: newValue.name) { [self] in
			isPressed = true
		}

		KeyboardShortcuts.onKeyUp(for: newValue.name) { [self] in
			isPressed = false
		}
	}

	var body: some View {
		VStack(alignment: .leading) {
			Text("Dynamic recorder")
			VStack {
				Picker("Select shortcut:", selection: $shortcut.onChange(onShortcutChange)) {
					ForEach(shortcuts) {
						Text($0.id).tag($0)
					}
				}
				Spacer()
				Divider()
				DynamicShortcutRecorder(name: $shortcut.name, isPressed: $isPressed)
			}.padding([.top, .bottom], 60)
		}
		.frame(maxWidth: 300)
		.onAppear {
			KeyboardShortcuts.onKeyDown(for: shortcut.name) { [self] in
				isPressed = true
			}

			KeyboardShortcuts.onKeyUp(for: shortcut.name) { [self] in
				isPressed = false
			}
		}
	}
}

struct DoubleShortcut: View {
	@State private var isPressed1 = false
	@State private var isPressed2 = false

	var body: some View {
		VStack {
			HStack {
				KeyboardShortcuts.Recorder(for: .testShortcut1)
					.padding(.trailing, 10)
				Text("Pressed? \(isPressed1 ? "👍" : "👎")")
					.frame(width: 100, alignment: .leading)
			}
			HStack {
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
			.padding(60)
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
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
