import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut1")
	static let testShortcut2 = Self("testShortcut2")
}

struct ContentView: View {
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

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
