import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut1")
	static let testShortcut2 = Self("testShortcut2")
	static let testShortcut3 = Self("testShortcut3")
	static let testShortcut4 = Self("testShortcut4")
}

struct Shortcut {
	var name: KeyboardShortcuts.Name
	let label: String
}

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

final class DynamicShortcutViewModel: ObservableObject {
	@Published var isPressed = false
	@Published var selectedState = 0 {
		didSet {
			KeyboardShortcuts.disable(shortcuts[oldValue].name)
			setShortcutEvent(name: shortcuts[selectedState].name)
		}
	}

	var selectedLabel: Binding<String> {
		Binding(
			get: {
				self.shortcuts[self.selectedState].label
			},
			set: { label in
				self.selectedState = self.shortcuts.firstIndex { $0.label == label } ?? 0
			}
		)
	}

	var selectedName: Binding<KeyboardShortcuts.Name> {
		Binding(
			get: {
				self.shortcuts[self.selectedState].name
			},
			set: { name in
				self.selectedState = self.shortcuts.firstIndex { $0.name == name } ?? 0
			}
		)
	}

	var shortcuts = [
		Shortcut(name: .testShortcut3, label: "Shortcut3"),
		Shortcut(name: .testShortcut4, label: "Shortcut4")
	]

	init() {
		setShortcutEvent(name: shortcuts[selectedState].name)
	}

	func setShortcutEvent(name: KeyboardShortcuts.Name) {
		KeyboardShortcuts.onKeyDown(for: name) {
			self.isPressed = true
		}

		KeyboardShortcuts.onKeyUp(for: name) {
			self.isPressed = false
		}
	}
}

struct DynamicShortcut: View {
	@ObservedObject private var viewModel = DynamicShortcutViewModel()
	@State private var shortcutName: KeyboardShortcuts.Name = .testShortcut3

	var body: some View {
		VStack {
			Text("Dynamic recorder").frame(maxWidth: .infinity, alignment: .leading)
			VStack {
				Picker("Select shortcut:", selection: viewModel.selectedLabel) {
					ForEach(viewModel.shortcuts, id: \.label) {
						Text($0.label)
					}
				}
				HStack {
					DynamicShortcutRecorder(name: viewModel.selectedName, isPressed: $viewModel.isPressed)
				}
			}.padding(60)
		}
		.frame(maxWidth: 300)
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
