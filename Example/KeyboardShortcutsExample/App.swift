import SwiftUI

@main
struct AppMain: App {
	@StateObject private var state = AppState()

	var body: some Scene {
		WindowGroup {
			MainScreen()
				.task {
					state.createMenus()
				}
		}
	}
}
