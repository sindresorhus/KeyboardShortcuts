#if os(macOS)
import AppKit
import Carbon.HIToolbox

extension KeyboardShortcuts {
		public struct RecorderOption {
			// Allow recording only the `Shift` modifier key like `shift+a`
			// The “shift” key is not allowed without other modifiers or a function key after macOS 14
			public let allowOnlyShiftModifier: Bool

			// Check if the keyboard shortcut is already taken by the app's main menu
			public let checkMenuCollision: Bool

			// Allow recording a sequence of shortcuts
			public let enableSequences: Bool

			// The maximum number of shortcuts in a sequence.
			public let maxSequenceLength: Int

			public init(
				allowOnlyShiftModifier: Bool = false,
				checkMenuCollision: Bool = true,
				enableSequences: Bool = false,
				maxSequenceLength: Int = 2
			) {
				self.allowOnlyShiftModifier = allowOnlyShiftModifier
				self.checkMenuCollision = checkMenuCollision
				self.enableSequences = enableSequences
				self.maxSequenceLength = maxSequenceLength
			}
		}

	/**
	A `NSView` that lets the user record a keyboard shortcut.

	You would usually put this in your settings window.

	It automatically prevents choosing a keyboard shortcut that is already taken by the system or by the app's main menu by showing a user-friendly alert to the user.

	It takes care of storing the keyboard shortcut in `UserDefaults` for you.

	```swift
	import AppKit
	import KeyboardShortcuts

	final class SettingsViewController: NSViewController {
		override func loadView() {
			view = NSView()

			let recorder = KeyboardShortcuts.RecorderCocoa(for: .toggleUnicornMode)
			view.addSubview(recorder)
		}
	}
	```
	*/
	public final class RecorderCocoa: NSSearchField, NSSearchFieldDelegate {
		public enum StorageMode {
			// `.persist` mode does not support sequences.
			case persist(Name, onChange: ((_ shortcut: Shortcut?) -> Void)?)
			// `.binding` mode can support sequences.
			case binding(get: () -> [Shortcut], set: ([Shortcut]) -> Void)
		}
		private let minimumWidth = 130.0
		private let storageMode: StorageMode
		private var canBecomeKey = false
		private var eventMonitor: LocalEventMonitor?
		private var shortcutsNameChangeObserver: NSObjectProtocol?
		private var windowDidResignKeyObserver: NSObjectProtocol?
		private var windowDidBecomeKeyObserver: NSObjectProtocol?
		private let recorderOption: RecorderOption

		// For sequence recording.
		private var recordedChords: [Shortcut] = []
		private var recordingTimer: Timer?

		/**
		The shortcut name for the recorder.

		Can be dynamically changed at any time.
		*/
		public var shortcutName: Name {
			didSet {
				guard shortcutName != oldValue else {
					return
				}

				setStringValue(name: shortcutName)

				// This doesn't seem to be needed anymore, but I cannot test on older OS versions, so keeping it just in case.
				if #unavailable(macOS 12) {
					DispatchQueue.main.async { [self] in
						// Prevents the placeholder from being cut off.
						blur()
					}
				}
			}
		}

		/// :nodoc:
		override public var canBecomeKeyView: Bool { canBecomeKey }

		/// :nodoc:
		override public var intrinsicContentSize: CGSize {
			var size = super.intrinsicContentSize
			size.width = minimumWidth
			return size
		}

		private var cancelButton: NSButtonCell?

		private var showsCancelButton: Bool {
			get { (cell as? NSSearchFieldCell)?.cancelButtonCell != nil }
			set {
				(cell as? NSSearchFieldCell)?.cancelButtonCell = newValue ? cancelButton : nil
			}
		}

		/**
		- Parameter name: Strongly-typed keyboard shortcut name.
		- Parameter onChange: Callback which will be called when the keyboard shortcut is changed/removed by the user. This can be useful when you need more control. For example, when migrating from a different keyboard shortcut solution and you need to store the keyboard shortcut somewhere yourself instead of relying on the built-in storage. However, it's strongly recommended to just rely on the built-in storage when possible.
		*/
		public required init(
			for name: Name,
				onChange: ((_ shortcut: Shortcut?) -> Void)? = nil,
				option: RecorderOption = RecorderOption()
		) {
			precondition(!option.enableSequences, "The `.persist` storage mode for KeyboardShortcuts.RecorderCocoa does not support sequences.")
			self.shortcutName = name
			self.storageMode = .persist(name, onChange: onChange)
				self.recorderOption = option

			super.init(frame: .zero)
			self.delegate = self
			self.placeholderString = "record_shortcut".localized
			self.alignment = .center
			(cell as? NSSearchFieldCell)?.searchButtonCell = nil

			self.wantsLayer = true
			setContentHuggingPriority(.defaultHigh, for: .vertical)
			setContentHuggingPriority(.defaultHigh, for: .horizontal)

			// Hide the cancel button when not showing the shortcut so the placeholder text is properly centered. Must be last.
			self.cancelButton = (cell as? NSSearchFieldCell)?.cancelButtonCell

			setStringValue(name: name)

			setUpEvents()
		}

		public init(
			get: @escaping () -> [Shortcut],
				set: @escaping ([Shortcut]) -> Void,
				option: RecorderOption = RecorderOption()
		) {
			self.storageMode = .binding(get: get, set: set)
			// Not used in binding mode, but must be initialized.
			self.shortcutName = .init("_binding")
				self.recorderOption = option

			super.init(frame: .zero)
			self.delegate = self
			self.placeholderString = "record_shortcut".localized
			self.alignment = .center
			(cell as? NSSearchFieldCell)?.searchButtonCell = nil

			self.wantsLayer = true
			setContentHuggingPriority(.defaultHigh, for: .vertical)
			setContentHuggingPriority(.defaultHigh, for: .horizontal)

			// Hide the cancel button when not showing the shortcut so the placeholder text is properly centered. Must be last.
			self.cancelButton = (cell as? NSSearchFieldCell)?.cancelButtonCell

			// Initialize display from binding source
			if case let .binding(get, _) = storageMode {
				let current = get()
				stringValue = current.presentableDescription
				showsCancelButton = !stringValue.isEmpty
			}

			setUpEvents()
		}

		@available(*, unavailable)
		public required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

		private func setStringValue(name: KeyboardShortcuts.Name) {
			stringValue = getShortcut(for: shortcutName).map { "\($0)" } ?? ""

			// If `stringValue` is empty, hide the cancel button to let the placeholder center.
			showsCancelButton = !stringValue.isEmpty
		}

		private func setUpEvents() {
			// Only observe name-based changes when in persist mode.
			guard case .persist = storageMode else { return }

			shortcutsNameChangeObserver = NotificationCenter.default.addObserver(forName: .shortcutByNameDidChange, object: nil, queue: nil) { [weak self] notification in
				guard
					let self,
					let nameInNotification = notification.userInfo?["name"] as? KeyboardShortcuts.Name,
					nameInNotification == shortcutName
				else {
					return
				}

				setStringValue(name: nameInNotification)
			}
		}

		private func endRecording() {
			eventMonitor = nil
			placeholderString = "record_shortcut".localized
			showsCancelButton = !stringValue.isEmpty
			restoreCaret()
			KeyboardShortcuts.isPaused = false
			NotificationCenter.default.post(name: .recorderActiveStatusDidChange, object: nil, userInfo: ["isActive": false])
		}

		private func preventBecomingKey() {
			canBecomeKey = false

			// Prevent the control from receiving the initial focus.
			DispatchQueue.main.async { [self] in
				canBecomeKey = true
			}
		}

		/// :nodoc:
		public func controlTextDidChange(_ object: Notification) {
			if stringValue.isEmpty {
				// Pass an empty array for non-optional bindings.
				saveShortcut([])
			}

			showsCancelButton = !stringValue.isEmpty

			if stringValue.isEmpty {
				// Hack to ensure that the placeholder centers after the above `showsCancelButton` setter.
				focus()
			}
		}

		/// :nodoc:
		public func controlTextDidEndEditing(_ object: Notification) {
			endRecording()
		}

		/// :nodoc:
		override public func viewDidMoveToWindow() {
			guard let window else {
				windowDidResignKeyObserver = nil
				windowDidBecomeKeyObserver = nil
				endRecording()
				return
			}

			// Ensures the recorder stops when the window is hidden.
			// This is especially important for Settings windows, which as of macOS 13.5, only hides instead of closes when you click the close button.
			windowDidResignKeyObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: nil) { [weak self] _ in
				guard
					let self,
					let window = self.window
				else {
					return
				}

				endRecording()
				window.makeFirstResponder(nil)
			}

			// Ensures the recorder does not receive initial focus when a hidden window becomes unhidden.
			windowDidBecomeKeyObserver = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: nil) { [weak self] _ in
				self?.preventBecomingKey()
			}

			preventBecomingKey()
		}

		/// :nodoc:
		override public func becomeFirstResponder() -> Bool {
			let shouldBecomeFirstResponder = super.becomeFirstResponder()

			guard shouldBecomeFirstResponder else {
				return shouldBecomeFirstResponder
			}

			placeholderString = "press_shortcut".localized
			showsCancelButton = !stringValue.isEmpty
			hideCaret()
			KeyboardShortcuts.isPaused = true // The position here matters.
			NotificationCenter.default.post(name: .recorderActiveStatusDidChange, object: nil, userInfo: ["isActive": true])

			eventMonitor = LocalEventMonitor(events: [.keyDown, .leftMouseUp, .rightMouseUp]) { [weak self] event in
				guard let self else {
					return nil
				}

				let clickPoint = convert(event.locationInWindow, from: nil)
				let clickMargin = 3.0

				if
					event.type == .leftMouseUp || event.type == .rightMouseUp,
					!bounds.insetBy(dx: -clickMargin, dy: -clickMargin).contains(clickPoint)
				{
					blur()
					return event
				}

				guard event.isKeyEvent else {
					return nil
				}

				if
					event.modifiers.isEmpty,
					event.specialKey == .tab
				{
					blur()

					// We intentionally bubble up the event so it can focus the next responder.
					return event
				}

				if
					event.modifiers.isEmpty,
					event.keyCode == kVK_Escape // TODO: Make this strongly typed.
				{
					blur()
					return nil
				}

				if
					event.modifiers.isEmpty,
					event.specialKey == .delete
						|| event.specialKey == .deleteForward
						|| event.specialKey == .backspace
				{
					clear()
					return nil
				}

				guard
					self.recorderOption.allowOnlyShiftModifier
						|| (!event.modifiers.subtracting([.shift, .function]).isEmpty
							|| event.specialKey?.isFunctionKey == true),
					let newShortcut = Shortcut(event: event)
				else {
					NSSound.beep()
					return nil
				}

				// Perform collision checks for the new chord.
				if self.recorderOption.checkMenuCollision, let menuItem = newShortcut.takenByMainMenu {
					blur()
					NSAlert.showModal(for: window, title: String.localizedStringWithFormat("keyboard_shortcut_used_by_menu_item".localized, menuItem.title))
					focus()
					return nil
				}

				if !self.recorderOption.allowOnlyShiftModifier && newShortcut.isDisallowed {
					blur()
					NSAlert.showModal(for: window, title: "keyboard_shortcut_disallowed".localized)
					focus()
					return nil
				}

				if newShortcut.isTakenBySystem {
					blur()
					let modalResponse = NSAlert.showModal(for: window, title: "keyboard_shortcut_used_by_system".localized, message: "keyboard_shortcuts_can_be_changed".localized, buttonTitles: ["ok".localized, "force_use_shortcut".localized])
					focus()
					guard modalResponse == .alertSecondButtonReturn else {
						return nil
					}
				}

				// If sequences are not enabled, finalize recording immediately.
				guard self.recorderOption.enableSequences else {
					stringValue = newShortcut.description
					showsCancelButton = true
					saveShortcut([newShortcut])
					blur()
					return nil
				}

				// If sequences are enabled, append and wait for the next chord or timeout.
				recordedChords.append(newShortcut)

				// If the sequence reaches its maximum length, finalize the recording immediately.
				if recordedChords.count >= self.recorderOption.maxSequenceLength {
					finalizeRecording()
					return nil
				}

				stringValue = recordedChords.presentableDescription + "…"
				showsCancelButton = true

				// Reset the timer. If it fires, the recording is finalized.
				recordingTimer?.invalidate()
				recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
					self?.finalizeRecording()
				}

				return nil
			}.start()

			return shouldBecomeFirstResponder
		}

		private func saveShortcut(_ shortcuts: [Shortcut]) {
			switch storageMode {
			case .persist(_, let onChange):
				// `.persist` mode only supports single shortcuts.
				let shortcut = shortcuts.first
				setShortcut(shortcut, for: shortcutName)
				onChange?(shortcut)
			case .binding(_, let set):
				set(shortcuts)
			}
		}

		private func finalizeRecording() {
			recordingTimer?.invalidate()
			recordingTimer = nil

			guard !recordedChords.isEmpty else {
				blur()
				return
			}

			let finalShortcuts = recordedChords
			recordedChords = []

			stringValue = finalShortcuts.presentableDescription
			saveShortcut(finalShortcuts)
			blur()
		}
	}
}

extension Notification.Name {
	static let recorderActiveStatusDidChange = Self("KeyboardShortcuts_recorderActiveStatusDidChange")
}
#endif
