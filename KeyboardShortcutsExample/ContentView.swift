import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut1")
	static let testShortcut2 = Self("testShortcut2")
}

struct ShortCut {
	let name: KeyboardShortcuts.Name
	let id: Int8
	let label: String
}

struct ContentView: View {
	@State private var isPressed = false
	@State private var selectedState = 0
	var shortCuts = [
		ShortCut(name: .testShortcut1, id: 0, label: "ShortCut1"),
		ShortCut(name: .testShortcut2, id: 1, label: "ShortCut2")
	]

	private var selectedShortCut: Binding<Int> {
		Binding(get: {
			self.selectedState
		}, set: {
			KeyboardShortcuts.disable(self.shortCuts[self.selectedState].name)
			KeyboardShortcuts.onKeyDown(for: self.shortCuts[$0].name) {
				self.isPressed = true
			}
			KeyboardShortcuts.onKeyUp(for: self.shortCuts[$0].name) {
				self.isPressed = false
			}
			self.selectedState = $0
		})
	}

	var body: some View {
		VStack {
			Picker(selection: selectedShortCut, label: Text("Select shortcut :")) {
				ForEach(0 ..< shortCuts.count) {
					Text(self.shortCuts[$0].label)
				}
			}
			HStack {
				KeyboardShortcuts.Recorder(for: self.shortCuts[selectedState].name)
					.padding(.trailing, 10)
				Text("Pressed? \(self.isPressed ? "👍" : "👎")")
					.frame(width: 100, alignment: .leading)
			}.padding(.top, 8)
		}
			.frame(maxWidth: 300)
			.padding(60)
			.onAppear {
				KeyboardShortcuts.onKeyDown(for: self.shortCuts[self.selectedState].name) {
					self.isPressed = true
				}
				KeyboardShortcuts.onKeyUp(for: self.shortCuts[self.selectedState].name) {
					self.isPressed = false
				}
			}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
