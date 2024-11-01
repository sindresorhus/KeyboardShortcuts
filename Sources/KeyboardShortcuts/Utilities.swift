#if os(macOS)
import Carbon.HIToolbox
import SwiftUI


extension String {
	/**
	Makes the string localizable.
	*/
	var localized: String {
		NSLocalizedString(self, bundle: .module, comment: self)
	}
}


extension Data {
	var toString: String? { String(data: self, encoding: .utf8) }
}


extension NSEvent {
	var isKeyEvent: Bool { type == .keyDown || type == .keyUp }
}


extension NSTextField {
	func hideCaret() {
		(currentEditor() as? NSTextView)?.insertionPointColor = .clear
	}

    func restoreCaret() {
        (currentEditor() as? NSTextView)?.insertionPointColor = .labelColor
    }
}


extension NSView {
	func focus() {
		window?.makeFirstResponder(self)
	}

	func blur() {
		window?.makeFirstResponder(nil)
	}
}


/**
Listen to local events.

- Important: Don't foret to call `.start()`.

```
eventMonitor = LocalEventMonitor(events: [.leftMouseDown, .rightMouseDown]) { event in
	// Do something

	return event
}.start()
```
*/
final class LocalEventMonitor {
	private let events: NSEvent.EventTypeMask
	private let callback: (NSEvent) -> NSEvent?
	private weak var monitor: AnyObject?

	init(events: NSEvent.EventTypeMask, callback: @escaping (NSEvent) -> NSEvent?) {
		self.events = events
		self.callback = callback
	}

	deinit {
		stop()
	}

	@discardableResult
	func start() -> Self {
		monitor = NSEvent.addLocalMonitorForEvents(matching: events, handler: callback) as AnyObject
		return self
	}

	func stop() {
		guard let monitor else {
			return
		}

		NSEvent.removeMonitor(monitor)
	}
}


final class RunLoopLocalEventMonitor {
	private let runLoopMode: RunLoop.Mode
	private let callback: (NSEvent) -> NSEvent?
	private let observer: CFRunLoopObserver

	init(
		events: NSEvent.EventTypeMask,
		runLoopMode: RunLoop.Mode,
		callback: @escaping (NSEvent) -> NSEvent?
	) {
		self.runLoopMode = runLoopMode
		self.callback = callback

		self.observer = CFRunLoopObserverCreateWithHandler(nil, CFRunLoopActivity.beforeSources.rawValue, true, 0) { _, _ in
			// Pull all events from the queue and handle the ones matching the given types.
			// Non-matching events are left untouched, maintaining their order in the queue.

			var eventsToHandle = [NSEvent]()

			// Retrieve all events from the event queue to preserve their order (instead of using the `matching` parameter).
			while let eventToHandle = NSApp.nextEvent(matching: .any, until: nil, inMode: .default, dequeue: true) {
				eventsToHandle.append(eventToHandle)
			}

			// Iterate over the gathered events, instead of doing it directly in the `while` loop, to avoid potential infinite loops caused by re-retrieving undiscarded events.
			for eventToHandle in eventsToHandle {
				var handledEvent: NSEvent?

				if !events.contains(NSEvent.EventTypeMask(rawValue: 1 << eventToHandle.type.rawValue)) {
					handledEvent = eventToHandle
				} else if let callbackEvent = callback(eventToHandle) {
					handledEvent = callbackEvent
				}

				guard let handledEvent else {
					continue
				}

				NSApp.postEvent(handledEvent, atStart: false)
			}
		}
	}

	deinit {
		stop()
	}

	@discardableResult
	func start() -> Self {
		CFRunLoopAddObserver(RunLoop.current.getCFRunLoop(), observer, CFRunLoopMode(runLoopMode.rawValue as CFString))
		return self
	}

	func stop() {
		CFRunLoopRemoveObserver(RunLoop.current.getCFRunLoop(), observer, CFRunLoopMode(runLoopMode.rawValue as CFString))
	}
}


extension NSEvent {
	static var modifiers: ModifierFlags {
		modifierFlags
			.intersection(.deviceIndependentFlagsMask)
			// We remove `capsLock` as it shouldn't affect the modifiers.
			// We remove `numericPad` as arrow keys trigger it, use `event.specialKeys` instead.
			.subtracting([.capsLock, .numericPad])
	}

	/**
	Real modifiers.

	- Note: Prefer this over `.modifierFlags`.

	```
	// Check if Command is one of possible more modifiers keys
	event.modifiers.contains(.command)

	// Check if Command is the only modifier key
	event.modifiers == .command

	// Check if Command and Shift are the only modifiers
	event.modifiers == [.command, .shift]
	```
	*/
	var modifiers: ModifierFlags {
		modifierFlags
			.intersection(.deviceIndependentFlagsMask)
			// We remove `capsLock` as it shouldn't affect the modifiers.
			// We remove `numericPad` as arrow keys trigger it, use `event.specialKeys` instead.
			.subtracting([.capsLock, .numericPad])
	}
}


extension NSSearchField {
	/**
	Clear the search field.
	*/
	func clear() {
		(cell as? NSSearchFieldCell)?.cancelButtonCell?.performClick(self)
	}
}


extension NSAlert {
	/**
	Show an alert as a window-modal sheet, or as an app-modal (window-independent) alert if the window is `nil` or not given.
	*/
	@discardableResult
	static func showModal(
		for window: NSWindow? = nil,
		title: String,
		message: String? = nil,
		style: Style = .warning,
		icon: NSImage? = nil,
		buttonTitles: [String] = []
	) -> NSApplication.ModalResponse {
		NSAlert(
			title: title,
			message: message,
			style: style,
			icon: icon,
			buttonTitles: buttonTitles
		).runModal(for: window)
	}

	convenience init(
		title: String,
		message: String? = nil,
		style: Style = .warning,
		icon: NSImage? = nil,
		buttonTitles: [String] = []
	) {
		self.init()
		self.messageText = title
		self.alertStyle = style
		self.icon = icon

		for buttonTitle in buttonTitles {
			addButton(withTitle: buttonTitle)
		}

		if let message {
			self.informativeText = message
		}
	}

	/**
	Runs the alert as a window-modal sheet, or as an app-modal (window-independent) alert if the window is `nil` or not given.
	*/
	@discardableResult
	func runModal(for window: NSWindow? = nil) -> NSApplication.ModalResponse {
		guard let window else {
			return runModal()
		}

		beginSheetModal(for: window) { returnCode in
			NSApp.stopModal(withCode: returnCode)
		}

		return NSApp.runModal(for: window)
	}
}


enum UnicodeSymbols {
	/**
	Represents the Function (Fn) key on the keybord.
	*/
	static let functionKey = "🌐\u{FE0E}"
}


extension NSEvent.ModifierFlags {
	// Not documented anywhere, but reverse-engineered by me.
	private static let functionKey = 1 << 17 // 131072 (0x20000)

	var carbon: Int {
		var modifierFlags = 0

		if contains(.control) {
			modifierFlags |= controlKey
		}

		if contains(.option) {
			modifierFlags |= optionKey
		}

		if contains(.shift) {
			modifierFlags |= shiftKey
		}

		if contains(.command) {
			modifierFlags |= cmdKey
		}

		if contains(.function) {
			modifierFlags |= Self.functionKey
		}

		return modifierFlags
	}

	init(carbon: Int) {
		self.init()

		if carbon & controlKey == controlKey {
			insert(.control)
		}

		if carbon & optionKey == optionKey {
			insert(.option)
		}

		if carbon & shiftKey == shiftKey {
			insert(.shift)
		}

		if carbon & cmdKey == cmdKey {
			insert(.command)
		}

		if carbon & Self.functionKey == Self.functionKey {
			insert(.function)
		}
	}
}

extension SwiftUI.EventModifiers {
	// `.function` is deprecated, so we use the raw value.
	fileprivate static let function_nonDeprecated = Self(rawValue: 64)
}

extension NSEvent.ModifierFlags {
	var toEventModifiers: SwiftUI.EventModifiers {
		var modifiers = SwiftUI.EventModifiers()

		if contains(.capsLock) {
			modifiers.insert(.capsLock)
		}

		if contains(.command) {
			modifiers.insert(.command)
		}

		if contains(.control) {
			modifiers.insert(.control)
		}

		if contains(.numericPad) {
			modifiers.insert(.numericPad)
		}

		if contains(.option) {
			modifiers.insert(.option)
		}

		if contains(.shift) {
			modifiers.insert(.shift)
		}

		if contains(.function) {
			modifiers.insert(.function_nonDeprecated)
		}

		return modifiers
	}
}

extension NSEvent.ModifierFlags {
	/**
	The string representation of the modifier flags.

	```
	print(NSEvent.ModifierFlags([.command, .shift]))
	//=> "⇧⌘"
	```
	*/
	var presentableDescription: String {
		var description = ""

		if contains(.control) {
			description += "⌃"
		}

		if contains(.option) {
			description += "⌥"
		}

		if contains(.shift) {
			description += "⇧"
		}

		if contains(.command) {
			description += "⌘"
		}

		if contains(.function) {
			description += UnicodeSymbols.functionKey
		}

		return description
	}
}


extension NSEvent.SpecialKey {
	static let functionKeys: Set<Self> = [
		.f1,
		.f2,
		.f3,
		.f4,
		.f5,
		.f6,
		.f7,
		.f8,
		.f9,
		.f10,
		.f11,
		.f12,
		.f13,
		.f14,
		.f15,
		.f16,
		.f17,
		.f18,
		.f19,
		.f20,
		.f21,
		.f22,
		.f23,
		.f24,
		.f25,
		.f26,
		.f27,
		.f28,
		.f29,
		.f30,
		.f31,
		.f32,
		.f33,
		.f34,
		.f35
	]

	var isFunctionKey: Bool { Self.functionKeys.contains(self) }
}


enum AssociationPolicy {
	case assign
	case retainNonatomic
	case copyNonatomic
	case retain
	case copy

	var rawValue: objc_AssociationPolicy {
		switch self {
		case .assign:
			.OBJC_ASSOCIATION_ASSIGN
		case .retainNonatomic:
			.OBJC_ASSOCIATION_RETAIN_NONATOMIC
		case .copyNonatomic:
			.OBJC_ASSOCIATION_COPY_NONATOMIC
		case .retain:
			.OBJC_ASSOCIATION_RETAIN
		case .copy:
			.OBJC_ASSOCIATION_COPY
		}
	}
}

final class ObjectAssociation<T> {
	private let policy: AssociationPolicy

	init(policy: AssociationPolicy = .retainNonatomic) {
		self.policy = policy
	}

	subscript(index: AnyObject) -> T? {
		get {
			// Force-cast is fine here as we want it to fail loudly if we don't use the correct type.
			// swiftlint:disable:next force_cast
			objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as! T?
		}
		set {
			objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, policy.rawValue)
		}
	}
}


extension HorizontalAlignment {
	private enum ControlAlignment: AlignmentID {
		static func defaultValue(in context: ViewDimensions) -> CGFloat { // swiftlint:disable:this no_cgfloat
			context[HorizontalAlignment.center]
		}
	}

	fileprivate static let controlAlignment = Self(ControlAlignment.self)
}

extension View {
	func formLabel(@ViewBuilder _ label: () -> some View) -> some View {
		HStack(alignment: .firstTextBaseline) {
			label()
			labelsHidden()
				.alignmentGuide(.controlAlignment) { $0[.leading] }
		}
		.alignmentGuide(.leading) { $0[.controlAlignment] }
	}
}


extension Dictionary {
	func hasKey(_ key: Key) -> Bool {
		index(forKey: key) != nil
	}
}
#endif


extension Sequence where Element: Hashable {
	/**
	Convert a `Sequence` with `Hashable` elements to a `Set`.
	*/
	func toSet() -> Set<Element> { Set(self) }
}


extension Set {
	/**
	Convert a `Set` to an `Array`.
	*/
	func toArray() -> [Element] { Array(self) }
}


extension StringProtocol {
	func replacingPrefix(_ prefix: String, with replacement: String) -> String {
		guard hasPrefix(prefix) else {
			return String(self)
		}

		return replacement + dropFirst(prefix.count)
	}
}
