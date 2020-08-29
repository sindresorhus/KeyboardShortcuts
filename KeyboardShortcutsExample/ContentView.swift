import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut1")
	static let testShortcut2 = Self("testShortcut2")
	static let testShortcut3 = Self("testShortcut3")
	static let testShortcut4 = Self("testShortcut4")
}

struct Shortcut {
	let name: KeyboardShortcuts.Name
	let label: String
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
					KeyboardShortcuts.Recorder(for: viewModel.shortcuts[viewModel.selectedState].name)
						.padding(.trailing, 10)
					Text("Pressed? \(viewModel.isPressed ? "👍" : "👎")")
						.frame(width: 100, alignment: .leading)
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
					self.isPressed1 = true
				}

				KeyboardShortcuts.onKeyUp(for: .testShortcut1) {
					self.isPressed1 = false
				}

				KeyboardShortcuts.onKeyDown(for: .testShortcut2) {
					self.isPressed2 = true
				}

				KeyboardShortcuts.onKeyUp(for: .testShortcut2) {
					self.isPressed2 = false
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
