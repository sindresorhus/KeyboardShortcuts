import Testing
import Foundation
import AppKit
import KeyboardShortcuts

@Suite("RecorderCocoa Layout Tests")
struct RecorderCocoaLayoutTests {
	@Test("RecorderCocoa has default size")
	func testRecorderDefaultSize() throws {
		let recorder = KeyboardShortcuts.RecorderCocoa(for: .init("test"))

		#expect(recorder.frame.width >= 130)
		#expect(recorder.frame.height > 0)
	}

	@Test("RecorderCocoa works with addSubview")
	@MainActor
	func testRecorderAddSubview() throws {
		let recorder = KeyboardShortcuts.RecorderCocoa(for: .init("test"))
		let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 100))

		containerView.addSubview(recorder)

		#expect(recorder.frame.size != .zero)
	}
}