#if os(macOS)
import AppKit
import Carbon.HIToolbox

extension KeyboardShortcuts {
	/**
	A `NSView` that lets the user record a keyboard shortcut.

	You would usually put this in your settings window.

	It automatically prevents choosing a keyboard shortcut that is already taken by the system or by the app's main menu by showing a user-friendly alert to the user.

	It takes care of storing the keyboard shortcut in `UserDefaults` for you when initialized with a name. When initialized with a shortcut value, it reads and writes the shortcut through the `shortcut` property.

	- Note: When initialized with a shortcut value, the shortcut is not automatically registered as a global hotkey. You are responsible for storing and handling the shortcut yourself.

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
		private enum StorageMode {
			case name
			case binding
		}

		private let minimumWidth = 130.0
		private let onChange: ((_ shortcut: Shortcut?) -> Void)?
		private let storageMode: StorageMode
		private var bindingShortcut: Shortcut?
		private var canBecomeKey = false
		private var eventMonitor: LocalEventMonitor?
		private var shortcutsNameChangeObserver: NSObjectProtocol?
		private var windowDidResignKeyObserver: NSObjectProtocol?
		private var windowDidBecomeKeyObserver: NSObjectProtocol?

		/**
		The shortcut name for the recorder.

		Can be dynamically changed at any time.

		This is only used when initialized with a name. In binding mode, changing this has no effect.
		*/
		public var shortcutName: Name {
			didSet {
				guard storageMode == .name else {
					assertionFailure("shortcutName is only available when initialized with a name.")
					return
				}

				guard shortcutName != oldValue else {
					return
				}

				updateStringValue()

				// This doesn't seem to be needed anymore, but I cannot test on older OS versions, so keeping it just in case.
				if #unavailable(macOS 12) {
					DispatchQueue.main.async { [self] in
						// Prevents the placeholder from being cut off.
						blur()
					}
				}
			}
		}

		/**
		The shortcut for the recorder.

		Use this when you manage the shortcut storage yourself.
		*/
		public var shortcut: Shortcut? {
			get { currentShortcut }
			set {
				guard newValue != currentShortcut else {
					return
				}

				storeShortcut(newValue)
				updateStringValue()
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
			onChange: ((_ shortcut: Shortcut?) -> Void)? = nil
		) {
			self.shortcutName = name
			self.onChange = onChange
			self.storageMode = .name

			// Use a default frame that matches our intrinsic size to prevent zero-size issues
			// when added without constraints (issue #209)
			super.init(frame: NSRect(x: 0, y: 0, width: minimumWidth, height: 24))
			configureView()

			updateStringValue()

			setUpEvents()
		}

		/**
		- Parameter shortcut: The initial keyboard shortcut value.
		- Parameter onChange: Callback which will be called when the keyboard shortcut is changed/removed by the user.
		*/
		public required init(
			shortcut: Shortcut?,
			onChange: ((_ shortcut: Shortcut?) -> Void)? = nil
		) {
			self.shortcutName = Name(rawValueWithoutInitialization: "")
			self.onChange = onChange
			self.storageMode = .binding
			self.bindingShortcut = shortcut

			// Use a default frame that matches our intrinsic size to prevent zero-size issues
			// when added without constraints (issue #209)
			super.init(frame: NSRect(x: 0, y: 0, width: minimumWidth, height: 24))
			configureView()

			updateStringValue()
		}

		@available(*, unavailable)
		public required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

		deinit {
			removeObserver(&shortcutsNameChangeObserver)
			removeObserver(&windowDidResignKeyObserver)
			removeObserver(&windowDidBecomeKeyObserver)
		}

		private func configureView() {
			delegate = self
			placeholderString = "record_shortcut".localized
			alignment = .center
			(cell as? NSSearchFieldCell)?.searchButtonCell = nil

			wantsLayer = true
			setContentHuggingPriority(.defaultHigh, for: .vertical)
			setContentHuggingPriority(.defaultHigh, for: .horizontal)

			// Hide the cancel button when not showing the shortcut so the placeholder text is properly centered. Must be last.
			cancelButton = (cell as? NSSearchFieldCell)?.cancelButtonCell
		}

		private func removeObserver(_ observer: inout NSObjectProtocol?) {
			guard let existingObserver = observer else {
				return
			}

			NotificationCenter.default.removeObserver(existingObserver)
			observer = nil
		}

		private var currentShortcut: Shortcut? {
			switch storageMode {
			case .name:
				return getShortcut(for: shortcutName)
			case .binding:
				return bindingShortcut
			}
		}

		private func storeShortcut(_ shortcut: Shortcut?) {
			switch storageMode {
			case .name:
				setShortcut(shortcut, for: shortcutName)
			case .binding:
				bindingShortcut = shortcut
			}
		}

		private func setStringValue(shortcut: Shortcut?) {
			stringValue = shortcut.map { "\($0)" } ?? ""

			// If `stringValue` is empty, hide the cancel button to let the placeholder center.
			showsCancelButton = !stringValue.isEmpty
		}

		private func updateStringValue() {
			setStringValue(shortcut: currentShortcut)
		}

		private func setUpEvents() {
			guard storageMode == .name else {
				return
			}

			shortcutsNameChangeObserver = NotificationCenter.default.addObserver(forName: .shortcutByNameDidChange, object: nil, queue: nil) { [weak self] notification in
				guard
					let self,
					let nameInNotification = notification.userInfo?["name"] as? KeyboardShortcuts.Name,
					nameInNotification == shortcutName
				else {
					return
				}

				updateStringValue()
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
				saveShortcut(nil)
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
				removeObserver(&windowDidResignKeyObserver)
				removeObserver(&windowDidBecomeKeyObserver)
				endRecording()
				return
			}

			removeObserver(&windowDidResignKeyObserver)
			removeObserver(&windowDidBecomeKeyObserver)

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
			// Ensure we have a valid window before attempting to become first responder
			// This prevents issues in SwiftUI contexts where the view hierarchy might not be fully established
			guard window != nil else {
				return false
			}

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

				// The “shift” key is not allowed without other modifiers or a function key, since it doesn't actually work.
				guard
					!event.modifiers.subtracting([.shift, .function]).isEmpty
						|| event.specialKey?.isFunctionKey == true,
					let shortcut = Shortcut(event: event)
				else {
					NSSound.beep()
					return nil
				}

				if let menuItem = shortcut.takenByMainMenu {
					// TODO: Find a better way to make it possible to dismiss the alert by pressing "Enter". How can we make the input automatically temporarily lose focus while the alert is open?
					blur()

					NSAlert.showModal(
						for: window,
						title: String.localizedStringWithFormat("keyboard_shortcut_used_by_menu_item".localized, menuItem.title)
					)

					focus()

					return nil
				}

				// See: https://developer.apple.com/forums/thread/763878?answerId=804374022#804374022
				if shortcut.isDisallowed {
					blur()

					NSAlert.showModal(
						for: window,
						title: "keyboard_shortcut_disallowed".localized
					)

					focus()
					return nil
				}

				if shortcut.isTakenBySystem {
					blur()

					let modalResponse = NSAlert.showModal(
						for: window,
						title: "keyboard_shortcut_used_by_system".localized,
						// TODO: Add button to offer to open the relevant system settings pane for the user.
						message: "keyboard_shortcuts_can_be_changed".localized,
						buttonTitles: [
							"ok".localized,
							"force_use_shortcut".localized
						]
					)

					focus()

					// If the user has selected "Use Anyway" in the dialog (the second option), we'll continue setting the keyboard shorcut even though it's reserved by the system.
					guard modalResponse == .alertSecondButtonReturn else {
						return nil
					}
				}

				stringValue = "\(shortcut)"
				showsCancelButton = true

				saveShortcut(shortcut)
				blur()

				return nil
			}.start()

			return shouldBecomeFirstResponder
		}

		private func saveShortcut(_ shortcut: Shortcut?) {
			storeShortcut(shortcut)
			onChange?(shortcut)
		}
	}
}

extension Notification.Name {
	static let recorderActiveStatusDidChange = Self("KeyboardShortcuts_recorderActiveStatusDidChange")
}
#endif
