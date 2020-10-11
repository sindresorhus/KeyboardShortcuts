//
//  Created by Honghao Zhang on 10/10/20.
//

import Foundation

extension CarbonLocalEventMonitor {
  /*
   1) Create a localEventMonitor:
   let localEventMonitor = CarbonLocalEventMonitor.monitor(for: .toggleUnicornMode) {
       // handle shortcut
   }

   2) Start when menu is open
   localEventMonitor.start()

   3) Stop when menu is closed
   localEventMonitor.stop()

   Example:

   menu.rx.menuOpenState
     .subscribe(onNext: { isOpen in
       if isOpen {
         KeyboardShortcuts.disable(.toggleUnicornMode)
         localEventMonitor.start()
       } else {
         KeyboardShortcuts.enable(.toggleUnicornMode)
         localEventMonitor.stop()
       }
     })
     .disposed(by: disposeBag)
   */
  public static func monitor(for name: KeyboardShortcuts.Name, handler: @escaping () -> Void) -> CarbonLocalEventMonitor {
    CarbonLocalEventMonitor(
      for: [.keyDown, .keyRepeat],
      useGlobalEventDispatcher: true
    ) { event in
      guard let shortcut = KeyboardShortcuts.getShortcut(for: name) else {
        return false
      }
      if event.isKeyEvent,
         event.keyCode == UInt16(shortcut.carbonKeyCode),
         // https://stackoverflow.com/a/32447474/3164091
         // should I intersect with .deviceIndependentFlagsMask?
         event.modifierFlags.intersection(.deviceIndependentFlagsMask).intersection(shortcut.modifiers) == shortcut.modifiers {
        handler()
        return true
      } else {
        return false
      }
    }
  }
}
