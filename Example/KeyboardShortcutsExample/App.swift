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
				.keyboardShortcut(menuShortcuts.shortcut1ForMenu?.toSwiftUI)
				.id(menuShortcuts.refreshID)
				Button("Shortcut 2") {
					AppState.shared.alert(2)
				}
				.keyboardShortcut(menuShortcuts.shortcut2ForMenu?.toSwiftUI)
				.id(menuShortcuts.refreshID)
				Button("Shortcut 3") {
					AppState.shared.alert(3)
				}
				.keyboardShortcut(menuShortcuts.shortcut3ForMenu?.toSwiftUI)
				.id(menuShortcuts.refreshID)
				Button("Shortcut 4") {
					AppState.shared.alert(4)
				}
				.keyboardShortcut(menuShortcuts.shortcut4ForMenu?.toSwiftUI)
				.id(menuShortcuts.refreshID)
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
	var isRecorderActive = false
	var refreshID = 0

	var shortcut1ForMenu: KeyboardShortcuts.Shortcut? {
		isRecorderActive ? nil : shortcut1
	}

	var shortcut2ForMenu: KeyboardShortcuts.Shortcut? {
		isRecorderActive ? nil : shortcut2
	}

	var shortcut3ForMenu: KeyboardShortcuts.Shortcut? {
		isRecorderActive ? nil : shortcut3
	}

	var shortcut4ForMenu: KeyboardShortcuts.Shortcut? {
		isRecorderActive ? nil : shortcut4
	}

	private var shortcutObserver: NSObjectProtocol?
	private var recorderActiveObserver: NSObjectProtocol?

	init() {
		shortcutObserver = NotificationCenter.default.addObserver(forName: Notification.Name("KeyboardShortcuts_shortcutByNameDidChange"), object: nil, queue: .main) { [weak self] notification in
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
					return
				}

				refreshID += 1
			}
		}

		recorderActiveObserver = NotificationCenter.default.addObserver(forName: Notification.Name("KeyboardShortcuts_recorderActiveStatusDidChange"), object: nil, queue: .main) { [weak self] notification in
			guard let self else {
				return
			}

			let isActive = (notification.userInfo?["isActive"] as? Bool) ?? false

			Task { @MainActor in
				isRecorderActive = isActive
				refreshID += 1
			}
		}
	}

	isolated deinit {
		if let shortcutObserver {
			NotificationCenter.default.removeObserver(shortcutObserver)
		}

		if let recorderActiveObserver {
			NotificationCenter.default.removeObserver(recorderActiveObserver)
		}
	}
}
