import SwiftUI
import Observation
import KeyboardShortcuts

@main
struct AppMain: App {
	@State private var menuShortcuts = TestMenuShortcuts()

	var body: some Scene {
		WindowGroup {
			MainScreen()
		}
		.windowResizability(.contentSize)
		.commands {
			CommandMenu("Test") {
				Button("Shortcut 1") {
					AppState.shared.alert(1)
				}
				.keyboardShortcut(menuShortcuts.shortcut1?.toSwiftUI)
				Button("Shortcut 2") {
					AppState.shared.alert(2)
				}
				.keyboardShortcut(menuShortcuts.shortcut2?.toSwiftUI)
				Button("Shortcut 3") {
					AppState.shared.alert(3)
				}
				.keyboardShortcut(menuShortcuts.shortcut3?.toSwiftUI)
				Button("Shortcut 4") {
					AppState.shared.alert(4)
				}
				.keyboardShortcut(menuShortcuts.shortcut4?.toSwiftUI)
			}
		}
	}
}

@MainActor
@Observable
final class TestMenuShortcuts {
	var shortcut1 = KeyboardShortcuts.getShortcut(for: .testShortcut1)
	var shortcut2 = KeyboardShortcuts.getShortcut(for: .testShortcut2)
	var shortcut3 = KeyboardShortcuts.getShortcut(for: .testShortcut3)
	var shortcut4 = KeyboardShortcuts.getShortcut(for: .testShortcut4)

	private var observer: NSObjectProtocol?

	init() {
		observer = NotificationCenter.default.addObserver(forName: Notification.Name("KeyboardShortcuts_shortcutByNameDidChange"), object: nil, queue: .main) { [weak self] notification in
			guard let self else {
				return
			}

			let name = notification.userInfo?["name"] as? KeyboardShortcuts.Name

			Task { @MainActor in
				guard let name else {
					return
				}

				switch name {
				case .testShortcut1:
					shortcut1 = KeyboardShortcuts.getShortcut(for: .testShortcut1)
				case .testShortcut2:
					shortcut2 = KeyboardShortcuts.getShortcut(for: .testShortcut2)
				case .testShortcut3:
					shortcut3 = KeyboardShortcuts.getShortcut(for: .testShortcut3)
				case .testShortcut4:
					shortcut4 = KeyboardShortcuts.getShortcut(for: .testShortcut4)
				default:
					break
				}
			}
		}
	}

	isolated deinit {
		guard let observer else {
			return
		}

		NotificationCenter.default.removeObserver(observer)
	}
}
