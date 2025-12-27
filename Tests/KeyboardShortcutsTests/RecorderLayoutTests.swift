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

	@Test("RecorderCocoa supports direct shortcut storage")
	@MainActor
	func testRecorderDirectShortcutStorage() throws {
		let shortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .shift])
		let recorder = KeyboardShortcuts.RecorderCocoa(shortcut: shortcut)

		#expect(recorder.shortcut == shortcut)
		#expect(recorder.stringValue == "\(shortcut)")

		recorder.shortcut = nil

		#expect(recorder.shortcut == nil)
		#expect(recorder.stringValue.isEmpty)
	}

	@Test("RecorderCocoa direct mode handles multiple shortcut changes")
	@MainActor
	func testRecorderDirectModeMultipleChanges() throws {
		let shortcut1 = KeyboardShortcuts.Shortcut(.a, modifiers: [.command])
		let shortcut2 = KeyboardShortcuts.Shortcut(.b, modifiers: [.command, .shift])
		let shortcut3 = KeyboardShortcuts.Shortcut(.c, modifiers: [.option, .control])

		let recorder = KeyboardShortcuts.RecorderCocoa(shortcut: nil)
		#expect(recorder.shortcut == nil)
		#expect(recorder.stringValue.isEmpty)

		recorder.shortcut = shortcut1
		#expect(recorder.shortcut == shortcut1)
		#expect(recorder.stringValue == "\(shortcut1)")

		recorder.shortcut = shortcut2
		#expect(recorder.shortcut == shortcut2)
		#expect(recorder.stringValue == "\(shortcut2)")

		recorder.shortcut = shortcut3
		#expect(recorder.shortcut == shortcut3)
		#expect(recorder.stringValue == "\(shortcut3)")

		recorder.shortcut = nil
		#expect(recorder.shortcut == nil)
		#expect(recorder.stringValue.isEmpty)
	}

	@Test("RecorderCocoa direct mode ignores redundant updates")
	@MainActor
	func testRecorderDirectModeRedundantUpdates() throws {
		let shortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command])
		let recorder = KeyboardShortcuts.RecorderCocoa(shortcut: shortcut)

		let originalStringValue = recorder.stringValue

		// Setting the same shortcut again should not cause issues
		recorder.shortcut = shortcut
		#expect(recorder.shortcut == shortcut)
		#expect(recorder.stringValue == originalStringValue)
	}
}
