import SwiftUI

@main
struct AppMain: App {
	var body: some Scene {
		WindowGroup {
			MainScreen()
				.task {
					AppState.shared.createMenus()
				}
		}
	}
}
