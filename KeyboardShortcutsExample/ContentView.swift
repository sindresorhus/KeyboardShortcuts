import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut1")
	static let testShortcut2 = Self("testShortcut2")
	static let testShortcut3 = Self("testShortcut3")
	static let testShortcut4 = Self("testShortcut4")
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

	private var selectedShortcut: Binding<Shortcut> {
		Binding(get: {
			shortcut
		}, set: {
			KeyboardShortcuts.disable(shortcut.name)
			setShortcutEvent(name: $0.name)
			shortcut = $0
		})
	}

	func setShortcutEvent(name: KeyboardShortcuts.Name) {
		KeyboardShortcuts.onKeyDown(for: name) { [self] in
			isPressed = true
		}

		KeyboardShortcuts.onKeyUp(for: name) { [self] in
			isPressed = false
		}
	}

	var body: some View {
		VStack {
			Text("Dynamic recorder").frame(maxWidth: .infinity, alignment: .leading)
			VStack {
				Picker("Select shortcut:", selection: selectedShortcut) {
					ForEach(shortcuts) {
						Text($0.id).tag($0)
					}
				}
				HStack {
					DynamicShortcutRecorder(name: $shortcut.name, isPressed: $isPressed)
				}
			}.padding(60)
		}
		.frame(maxWidth: 300)
		.onAppear {
			setShortcutEvent(name: shortcut.name)
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
