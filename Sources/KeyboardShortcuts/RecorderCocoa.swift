import Cocoa
import Carbon.HIToolbox

extension KeyboardShortcuts {
	/**
	A `NSView` that lets the user record a keyboard shortcut.

	You would usually put this in your preferences window.

	It automatically prevents choosing a keyboard shortcut that is already taken by the system or by the app's main menu by showing a user-friendly alert to the user.

	It takes care of storing the keyboard shortcut in `UserDefaults` for you.

	```
	import Cocoa
	import KeyboardShortcuts

	final class PreferencesViewController: NSViewController {
		override func loadView() {
			view = NSView()

			let recorder = KeyboardShortcuts.RecorderCocoa(for: .toggleUnicornMode)
			view.addSubview(recorder)
		}
	}
	```
	*/
	public final class RecorderCocoa: NSSearchField, NSSearchFieldDelegate {
		private let minimumWidth: Double = 130
		private var eventMonitor: LocalEventMonitor?
		private let shortcutName: Name

		/// :nodoc:
		override public var canBecomeKeyView: Bool { false }

		/// :nodoc:
		override public var intrinsicContentSize: CGSize {
			var size = super.intrinsicContentSize
			size.width = CGFloat(minimumWidth)
			return size
		}

		public required init(for name: Name) {
			self.shortcutName = name

			super.init(frame: .zero)
			self.delegate = self
			self.placeholderString = "Click to Record"
			self.centersPlaceholder = true
			self.alignment = .center
			(self.cell as? NSSearchFieldCell)?.searchButtonCell = nil

			if let shortcut = userDefaultsGet(name: shortcutName) {
				self.stringValue = "\(shortcut)"
			}

			self.wantsLayer = true
			self.translatesAutoresizingMaskIntoConstraints = false
			self.setContentHuggingPriority(.defaultHigh, for: .vertical)
			self.setContentHuggingPriority(.defaultHigh, for: .horizontal)
			self.widthAnchor.constraint(greaterThanOrEqualToConstant: CGFloat(minimumWidth)).isActive = true
		}

		@available(*, unavailable)
		public required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

		/// :nodoc:
		public func controlTextDidChange(_ object: Notification) {
			if stringValue.isEmpty {
				userDefaultsRemove(name: shortcutName)
			}
		}

		/// :nodoc:
		public func controlTextDidEndEditing(_ object: Notification) {
			eventMonitor = nil
			placeholderString = "Click to Record"
		}

		/// :nodoc:
		override public func becomeFirstResponder() -> Bool {
			let shouldBecomeFirstResponder = super.becomeFirstResponder()

			guard shouldBecomeFirstResponder else {
				return shouldBecomeFirstResponder
			}

			placeholderString = "Press Shortcut"
			hideCaret()

			eventMonitor = LocalEventMonitor(events: [.keyDown]) { [weak self] event in
				guard let self = self else {
					return nil
				}

				if
					event.modifiers.isEmpty,
					event.specialKey == .tab
				{
					return event
				}

				if
					event.modifiers.isEmpty,
					event.keyCode == kVK_Escape // TODO: Make this strongly typed.
				{
					self.blur()
					return nil
				}

				if
					event.modifiers.isEmpty &&
					(
						event.specialKey == .delete ||
						event.specialKey == .deleteForward ||
						event.specialKey == .backspace
					)
				{
					self.clear()
					return nil
				}

				guard
					(
						!event.modifiers.isEmpty ||
						event.specialKey?.isFunctionKey == true
					),
					let shortcut = Shortcut(event: event)
				else {
					NSSound.beep()
					return nil
				}

				if let menuItem = shortcut.takenByMainMenu {
					NSAlert.showModal(
						for: self.window,
						message: "This keyboard shortcut cannot be used as it's already used by the “\(menuItem.title)” menu item."
					)
					return nil
				}

				guard !shortcut.isTakenBySystem else {
					NSAlert.showModal(
						for: self.window,
						message: "This keyboard shortcut cannot be used as it's already a system-wide keyboard shortcut.",
						// TODO: Add button to offer to open the relevant system preference pane for the user.
						informativeText: "Most system-wide keyboard shortcuts can be changed in “System Preferences › Keyboard › Shortcuts“."
					)
					return nil
				}

				self.stringValue = "\(shortcut)"
				userDefaultsSet(name: self.shortcutName, shortcut: shortcut)
				self.blur()

				return nil
			}.start()

			return shouldBecomeFirstResponder
		}

		private func blur() {
			window?.makeFirstResponder(nil)
		}
	}
}
