#if os(macOS)
import AppKit
import Carbon.HIToolbox

/**
A global keyboard shortcut that automatically unregisters when deallocated.

This is a low-level wrapper around Carbon's hotkey registration. For most use cases, prefer the higher-level `KeyboardShortcuts` API.

- Important: Carbon only allows one registration per unique key combination. Attempting to register the same combination twice will fail.
*/
final class HotKey {
	let carbonKeyCode: Int
	let carbonModifiers: Int
	let onKeyDown: () -> Void
	let onKeyUp: () -> Void
	var onRegistrationFailed: (() -> Void)?

	fileprivate let id: Int
	fileprivate var eventHotKeyRef: EventHotKeyRef?

	/**
	Creates and registers a global keyboard shortcut.

	- Parameters:
		- carbonKeyCode: The virtual key code.
		- carbonModifiers: The modifier flags in Carbon format.
		- onKeyDown: Called when the shortcut key is pressed.
		- onKeyUp: Called when the shortcut key is released.
	- Returns: `nil` if registration fails (e.g., the key combination is already registered).
	*/
	init?(
		carbonKeyCode: Int,
		carbonModifiers: Int,
		onKeyDown: @escaping () -> Void,
		onKeyUp: @escaping () -> Void
	) {
		self.id = HotKeyCenter.shared.nextId()
		self.carbonKeyCode = carbonKeyCode
		self.carbonModifiers = carbonModifiers
		self.onKeyDown = onKeyDown
		self.onKeyUp = onKeyUp

		guard HotKeyCenter.shared.register(self) else {
			return nil
		}
	}

	deinit {
		HotKeyCenter.shared.unregister(self)
	}
}

/**
Manages global keyboard shortcut registrations and event routing.

This is an internal coordinator that handles:
- The shared Carbon event handler
- Routing events to the correct `HotKey` instance
- Switching between normal mode and menu mode (raw key events)
*/
final class HotKeyCenter {
	static let shared = HotKeyCenter()

	enum Mode {
		/**
		All hotkeys are disabled.
		*/
		case disabled

		/**
		Normal hotkey handling.
		*/
		case normal

		/**
		Menu is open - use raw key events instead of Carbon hotkeys.
		*/
		case menuOpen
	}

	private struct WeakHotKey {
		weak var value: HotKey?
	}

	private var lastHotKeyId = 0
	private var hotKeys = [Int: WeakHotKey]()
	private var eventHandler: EventHandlerRef?
	private var openMenuObserver: NSObjectProtocol?
	private var closeMenuObserver: NSObjectProtocol?
	private var isEnabled = true
	private(set) var isMenuOpen = false

	// `SSKS` is short for `Sindre Sorhus Keyboard Shortcuts`.
	// swiftlint:disable:next number_separator
	private let signature: UInt32 = 1397967699

	private let hotKeyEventTypes = [
		EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
		EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
	]

	private let rawKeyEventTypes = [
		EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventRawKeyDown)),
		EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventRawKeyUp))
	]

	private lazy var keyEventMonitor = RunLoopLocalEventMonitor(events: [.keyDown, .keyUp], runLoopMode: .eventTracking) { [weak self] event in
		guard
			let self,
			let eventRef = OpaquePointer(event.eventRef),
			handleRawKeyEvent(eventRef) == noErr
		else {
			return event
		}

		return nil
	}

	var mode: Mode = .normal {
		didSet {
			guard mode != oldValue else {
				return
			}

			updateEventHandler()
		}
	}

	private init() {
		setUpMenuTrackingObserversIfNeeded()
	}

	/**
	Sets whether global hotkeys are enabled and updates mode accordingly.
	*/
	func setEnabled(_ isEnabled: Bool) {
		guard self.isEnabled != isEnabled else {
			return
		}

		self.isEnabled = isEnabled
		updateMode()
	}

	/**
	Sets up menu tracking observers that toggle menu-open hotkey mode.
	*/
	private func setUpMenuTrackingObserversIfNeeded() {
		guard
			openMenuObserver == nil,
			closeMenuObserver == nil
		else {
			return
		}

		openMenuObserver = NotificationCenter.default.addObserver(forName: NSMenu.didBeginTrackingNotification, object: nil, queue: nil) { [weak self] _ in
			self?.setMenuOpenOnMainThread(true)
		}

		closeMenuObserver = NotificationCenter.default.addObserver(forName: NSMenu.didEndTrackingNotification, object: nil, queue: nil) { [weak self] _ in
			self?.setMenuOpenOnMainThread(false)
		}
	}

	private func setMenuOpenOnMainThread(_ isMenuOpen: Bool) {
		if Thread.isMainThread {
			setMenuOpen(isMenuOpen)
		} else {
			DispatchQueue.main.async { [weak self] in
				self?.setMenuOpen(isMenuOpen)
			}
		}
	}

	private func setMenuOpen(_ isMenuOpen: Bool) {
		guard self.isMenuOpen != isMenuOpen else {
			return
		}

		self.isMenuOpen = isMenuOpen
		updateMode()
	}

	private func updateMode() {
		mode = isEnabled ? (isMenuOpen ? .menuOpen : .normal) : .disabled
	}

	func nextId() -> Int {
		lastHotKeyId += 1
		return lastHotKeyId
	}

	func register(_ hotKey: HotKey) -> Bool {
		guard let eventHotKey = registerEventHotKey(for: hotKey) else {
			return false
		}

		hotKey.eventHotKeyRef = eventHotKey
		hotKeys[hotKey.id] = WeakHotKey(value: hotKey)
		setUpEventHandlerIfNeeded()
		updateEventHandler()

		return true
	}

	func unregister(_ hotKey: HotKey) {
		if let eventHotKeyRef = hotKey.eventHotKeyRef {
			UnregisterEventHotKey(eventHotKeyRef)
			hotKey.eventHotKeyRef = nil
		}

		hotKeys.removeValue(forKey: hotKey.id)
	}

	private func pause(_ hotKey: HotKey) {
		guard let eventHotKeyRef = hotKey.eventHotKeyRef else {
			return
		}

		UnregisterEventHotKey(eventHotKeyRef)
		hotKey.eventHotKeyRef = nil
	}

	private func resume(_ hotKey: HotKey) {
		guard hotKey.eventHotKeyRef == nil else {
			return
		}

		guard let eventHotKey = registerEventHotKey(for: hotKey) else {
			unregister(hotKey)
			hotKey.onRegistrationFailed?()
			return
		}

		hotKey.eventHotKeyRef = eventHotKey
	}

	private func registerEventHotKey(for hotKey: HotKey) -> EventHotKeyRef? {
		var eventHotKey: EventHotKeyRef?
		let error = RegisterEventHotKey(
			UInt32(hotKey.carbonKeyCode),
			UInt32(hotKey.carbonModifiers),
			EventHotKeyID(signature: signature, id: UInt32(hotKey.id)),
			GetEventDispatcherTarget(),
			0,
			&eventHotKey
		)

		guard
			error == noErr,
			let eventHotKey
		else {
			return nil
		}

		return eventHotKey
	}

	private func pauseAllHotKeys() {
		for hotKey in hotKeys.values.compactMap(\.value) {
			pause(hotKey)
		}
	}

	private func resumeAllHotKeys() {
		for hotKey in hotKeys.values.compactMap(\.value) {
			resume(hotKey)
		}
	}

	// MARK: - Event Handler

	private func setUpEventHandlerIfNeeded() {
		guard
			eventHandler == nil,
			let dispatcher = GetEventDispatcherTarget()
		else {
			return
		}

		var handler: EventHandlerRef?
		let error = InstallEventHandler(
			dispatcher,
			carbonEventHandler,
			0,
			nil,
			Unmanaged.passUnretained(self).toOpaque(),
			&handler
		)

		guard
			error == noErr,
			let handler
		else {
			return
		}

		eventHandler = handler
		updateEventHandler()
	}

	private func updateEventHandler() {
		guard eventHandler != nil else {
			return
		}

		let shouldHandleHotKeys = mode == .normal
		let shouldHandleRawKeys = mode == .menuOpen

		if shouldHandleHotKeys {
			resumeAllHotKeys()
		} else {
			pauseAllHotKeys()
		}

		setHotKeyEventHandlingEnabled(shouldHandleHotKeys)
		setRawKeyEventHandlingEnabled(shouldHandleRawKeys)
	}

	private func setHotKeyEventHandlingEnabled(_ isEnabled: Bool) {
		if isEnabled {
			AddEventTypesToHandler(eventHandler, hotKeyEventTypes.count, hotKeyEventTypes)
		} else {
			RemoveEventTypesFromHandler(eventHandler, hotKeyEventTypes.count, hotKeyEventTypes)
		}
	}

	private func setRawKeyEventHandlingEnabled(_ isEnabled: Bool) {
		if #available(macOS 14, *) {
			if isEnabled {
				keyEventMonitor.start()
			} else {
				keyEventMonitor.stop()
			}
		} else if isEnabled {
			AddEventTypesToHandler(eventHandler, rawKeyEventTypes.count, rawKeyEventTypes)
		} else {
			RemoveEventTypesFromHandler(eventHandler, rawKeyEventTypes.count, rawKeyEventTypes)
		}
	}

	fileprivate func handleEvent(_ event: EventRef?) -> OSStatus {
		guard let event else {
			return OSStatus(eventNotHandledErr)
		}

		switch Int(GetEventKind(event)) {
		case kEventHotKeyPressed, kEventHotKeyReleased:
			return handleHotKeyEvent(event)
		case kEventRawKeyDown, kEventRawKeyUp:
			return handleRawKeyEvent(event)
		default:
			return OSStatus(eventNotHandledErr)
		}
	}

	private func handleHotKeyEvent(_ event: EventRef) -> OSStatus {
		var eventHotKeyId = EventHotKeyID()
		let error = GetEventParameter(
			event,
			UInt32(kEventParamDirectObject),
			UInt32(typeEventHotKeyID),
			nil,
			MemoryLayout<EventHotKeyID>.size,
			nil,
			&eventHotKeyId
		)

		guard error == noErr else {
			return error
		}

		guard
			eventHotKeyId.signature == signature,
			let hotKey = hotKeys[Int(eventHotKeyId.id)]?.value
		else {
			return OSStatus(eventNotHandledErr)
		}

		switch Int(GetEventKind(event)) {
		case kEventHotKeyPressed:
			hotKey.onKeyDown()
			return noErr
		case kEventHotKeyReleased:
			hotKey.onKeyUp()
			return noErr
		default:
			return OSStatus(eventNotHandledErr)
		}
	}

	private func handleRawKeyEvent(_ event: EventRef) -> OSStatus {
		var eventKeyCode = UInt32()
		let keyCodeError = GetEventParameter(
			event,
			UInt32(kEventParamKeyCode),
			typeUInt32,
			nil,
			MemoryLayout<UInt32>.size,
			nil,
			&eventKeyCode
		)

		guard keyCodeError == noErr else {
			return keyCodeError
		}

		var eventKeyModifiers = UInt32()
		let keyModifiersError = GetEventParameter(
			event,
			UInt32(kEventParamKeyModifiers),
			typeUInt32,
			nil,
			MemoryLayout<UInt32>.size,
			nil,
			&eventKeyModifiers
		)

		guard keyModifiersError == noErr else {
			return keyModifiersError
		}

		let normalizedEventModifiers = normalizeModifiers(Int(eventKeyModifiers))

		// Find a hotkey matching this key combination
		guard let hotKey = hotKeys.values.lazy.compactMap(\.value).first(where: {
			$0.carbonKeyCode == Int(eventKeyCode) && normalizeModifiers($0.carbonModifiers) == normalizedEventModifiers
		}) else {
			return OSStatus(eventNotHandledErr)
		}

		switch Int(GetEventKind(event)) {
		case kEventRawKeyDown:
			hotKey.onKeyDown()
			return noErr
		case kEventRawKeyUp:
			hotKey.onKeyUp()
			return noErr
		default:
			return OSStatus(eventNotHandledErr)
		}
	}

	private func normalizeModifiers(_ carbonModifiers: Int) -> Int {
		// Carbon modifiers can be stored in multiple equivalent forms; normalize so raw events match registered shortcuts.
		NSEvent.ModifierFlags(carbon: carbonModifiers).carbon
	}
}

// Global C callback for Carbon event handler
private func carbonEventHandler(
	_: EventHandlerCallRef?,
	event: EventRef?,
	userData: UnsafeMutableRawPointer?
) -> OSStatus {
	guard let userData else {
		return OSStatus(eventNotHandledErr)
	}

	let center = Unmanaged<HotKeyCenter>.fromOpaque(userData).takeUnretainedValue()
	return center.handleEvent(event)
}

// MARK: - System Shortcuts

extension HotKeyCenter {
	/**
	Returns all system-defined keyboard shortcuts.
	*/
	static var systemShortcuts: [(carbonKeyCode: Int, carbonModifiers: Int)] {
		var shortcutsUnmanaged: Unmanaged<CFArray>?
		guard
			CopySymbolicHotKeys(&shortcutsUnmanaged) == noErr,
			let shortcuts = shortcutsUnmanaged?.takeRetainedValue() as? [[String: Any]]
		else {
			assertionFailure("Could not get system keyboard shortcuts")
			return []
		}

		return shortcuts.compactMap {
			guard
				($0[kHISymbolicHotKeyEnabled] as? Bool) == true,
				let carbonKeyCode = $0[kHISymbolicHotKeyCode] as? Int,
				let carbonModifiers = $0[kHISymbolicHotKeyModifiers] as? Int
			else {
				return nil
			}

			return (carbonKeyCode: carbonKeyCode, carbonModifiers: carbonModifiers)
		}
	}
}
#endif
