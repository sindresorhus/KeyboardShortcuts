import AppKit
import Carbon

// https://gist.github.com/sindresorhus/2bb90276ad608a22ee5e8fb291b35b88
/**
 Listen to local raw events using Carbon. The events are received before anything else gets access to them.
 The given callback should return a boolean of whether the event was handled or not. If it's marked as handled, it's not propagated.
 - Important: Don't forget to call `.start()`.
 This class is especially useful for menu bar apps using NSMenu as events will still be available even in the event tracking run loop. `NSEvent.addGlobalMonitorForEvents` does not work in the event tracking run loop, so this is the only reliable way to receive events while NSMenu is open.
 ```
 carbonEventMonitor = CarbonLocalEventMonitor(events: [.keyDown, .keyRepeat]) { event in
 // Do something
 return false
 }.start()
 ```
 */
public final class CarbonLocalEventMonitor {
  public enum EventType {
    case keyDown
    case keyRepeat
    case keyUp
    case keyModifiersChanged

    case mouseDown
    case mouseUp
    case mouseMoved
    case mouseDragged
    case mouseEntered
    case mouseExited
    case mouseWheelMoved
    case mouseScroll
  }

  private let events: Set<EventType>
  private let useGlobalEventDispatcher: Bool
  private let callback: (NSEvent) -> Bool
  private var eventHandler: EventHandlerRef?

  /**
   - Parameter useGlobalEventDispatcher: By default, it uses `GetApplicationEventTarget()`. Set this to true to use `GetEventDispatcherTarget()`, which will catch some additional events, for example, keyboard presses when a submenu is open in a NSMenu. Note that even when this is false, it still catches keyboard presses in NSMenu when a submenu is not open.
   */
  public init(
    for events: Set<EventType>,
    useGlobalEventDispatcher: Bool,
    callback: @escaping (NSEvent) -> Bool
  ) {
    self.events = events
    self.useGlobalEventDispatcher = useGlobalEventDispatcher
    self.callback = callback
  }

  deinit {
    stop()
  }

  private func processInterceptedEvent(_ eventRef: EventRef) -> Bool {
    guard let event = NSEvent(eventRef: UnsafeRawPointer(eventRef)) else {
      return false
    }

    return callback(event)
  }

  private func createSpec(_ eventClass: Int, _ eventKind: Int) -> EventTypeSpec {
    EventTypeSpec(eventClass: OSType(eventClass), eventKind: UInt32(eventKind))
  }

  @discardableResult
  public func start() -> Self {
    let dispatcherFunction = useGlobalEventDispatcher ? GetEventDispatcherTarget : GetApplicationEventTarget
    guard let dispatcher = dispatcherFunction() else {
      return self
    }

    var eventSpecs = [EventTypeSpec]()

    if events.contains(.keyDown) {
      eventSpecs.append(
        createSpec(kEventClassKeyboard, kEventRawKeyDown)
      )
    }

    if events.contains(.keyRepeat) {
      eventSpecs.append(
        createSpec(kEventClassKeyboard, kEventRawKeyRepeat)
      )
    }

    if events.contains(.keyUp) {
      eventSpecs.append(
        createSpec(kEventClassKeyboard, kEventRawKeyUp)
      )
    }

    if events.contains(.keyModifiersChanged) {
      eventSpecs.append(
        createSpec(kEventClassKeyboard, kEventRawKeyModifiersChanged)
      )
    }

    if events.contains(.mouseDown) {
      eventSpecs.append(
        createSpec(kEventClassMouse, kEventMouseDown)
      )
    }

    if events.contains(.mouseUp) {
      eventSpecs.append(
        createSpec(kEventClassMouse, kEventMouseUp)
      )
    }

    if events.contains(.mouseMoved) {
      eventSpecs.append(
        createSpec(kEventClassMouse, kEventMouseMoved)
      )
    }

    if events.contains(.mouseDragged) {
      eventSpecs.append(
        createSpec(kEventClassMouse, kEventMouseDragged)
      )
    }

    if events.contains(.mouseEntered) {
      eventSpecs.append(
        createSpec(kEventClassMouse, kEventMouseEntered)
      )
    }

    if events.contains(.mouseExited) {
      eventSpecs.append(
        createSpec(kEventClassMouse, kEventMouseExited)
      )
    }

    if events.contains(.mouseWheelMoved) {
      eventSpecs.append(
        createSpec(kEventClassMouse, kEventMouseWheelMoved)
      )
    }

    if events.contains(.mouseScroll) {
      eventSpecs.append(
        createSpec(kEventClassMouse, kEventMouseScroll)
      )
    }

    guard !events.isEmpty else {
      return self
    }

    let eventProcessorPointer = UnsafeMutablePointer<Any>.allocate(capacity: 1)
    eventProcessorPointer.initialize(to: processInterceptedEvent)

    let eventHandlerCallback: EventHandlerUPP = { _, eventRef, userData in
      guard
        let event = eventRef,
        let callbackPointer = userData
      else {
        return noErr
      }

      let eventProcessPointer = UnsafeMutablePointer<(EventRef) -> (Bool)>(OpaquePointer(callbackPointer))
      let isEventHandled = eventProcessPointer.pointee(event)

      if isEventHandled {
        return noErr
      } else {
        return OSStatus(Carbon.eventNotHandledErr)
      }
    }

    InstallEventHandler(
      dispatcher,
      eventHandlerCallback,
      eventSpecs.count,
      eventSpecs,
      eventProcessorPointer,
      &eventHandler
    )

    return self
  }

  public func stop() {
    guard let eventHandler = eventHandler else {
      return
    }

    RemoveEventHandler(eventHandler)
    self.eventHandler = nil
  }
}
