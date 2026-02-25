# Migration

A guide for migrating from other hotkey packages to KeyboardShortcuts.

## KeyboardShortcuts pattern

After migrating, you will:

1. Define `KeyboardShortcuts.Name`.
2. Use `KeyboardShortcuts.Recorder` or `KeyboardShortcuts.RecorderCocoa` in your settings UI.
3. Listen for events with `KeyboardShortcuts.events(for:)`.

```swift
import SwiftUI
import KeyboardShortcuts

// 1. Define a name
extension KeyboardShortcuts.Name {
	static let toggleMainWindow = Self("toggleMainWindow")
}

// 2. Add a recorder to your settings view
struct SettingsView: View {
	var body: some View {
		KeyboardShortcuts.Recorder("Toggle Main Window:", name: .toggleMainWindow)
	}
}

// 3. Listen for events (must be inside a Task or async context)
Task {
	for await eventType in KeyboardShortcuts.events(for: .toggleMainWindow) where eventType == .keyUp {
		toggleMainWindow()
	}
}
```

## [MASShortcut](https://github.com/cocoabits/MASShortcut) migration

### Before

```swift
import MASShortcut

shortcutView.associatedUserDefaultsKey = "toggleMainWindow"
MASShortcutBinder.shared().bindShortcut(withDefaultsKey: "toggleMainWindow") {
	toggleMainWindow()
}
```

### After

MASShortcut's binder fires on key-up, so match that:

```swift
import KeyboardShortcuts

// Inside a Task or async context
for await eventType in KeyboardShortcuts.events(for: .toggleMainWindow) where eventType == .keyUp {
	toggleMainWindow()
}
```

### Value migration

`MASShortcut` values are typically in `UserDefaults` for the old defaults key. Convert once:

```swift
import MASShortcut
import KeyboardShortcuts

func migrateMASShortcutValue(oldDefaultsKey: String, newName: KeyboardShortcuts.Name) {
	guard
		KeyboardShortcuts.getShortcut(for: newName) == nil,
		let legacyShortcut = UserDefaults.standard.object(forKey: oldDefaultsKey) as? MASShortcut
	else {
		return
	}

	KeyboardShortcuts.setShortcut(
		.init(
			carbonKeyCode: Int(legacyShortcut.keyCode),
			carbonModifiers: Int(legacyShortcut.modifierFlags)
		),
		for: newName
	)

	UserDefaults.standard.removeObject(forKey: oldDefaultsKey)
}
```

If your MASShortcut setup uses a custom transformer, keep your existing decode path and only change the final conversion to `KeyboardShortcuts.Shortcut(carbonKeyCode:carbonModifiers:)`.

## [Magnet](https://github.com/Clipy/Magnet) migration

### Before

```swift
import Magnet

let hotKey = HotKey(
	identifier: "toggleMainWindow",
	keyCombo: KeyCombo(key: .j, cocoaModifiers: [.command, .shift]),
	target: self,
	action: #selector(toggleMainWindow)
)

hotKey.keyDownHandler = {
	toggleMainWindow()
}

hotKey.keyUpHandler = {
	// Optional
}

HotKeyCenter.shared.register(with: hotKey)
```

### After

Magnet fires on key-down by default, so match that:

```swift
import KeyboardShortcuts

// Inside a Task or async context
for await eventType in KeyboardShortcuts.events(for: .toggleMainWindow) where eventType == .keyDown {
	toggleMainWindow()
}
```

### Value migration

Magnet is usually registration-only. If you did not persist `KeyCombo` yourself, there is nothing to migrate.

If you did persist values, convert once from your existing storage schema:

```swift
import KeyboardShortcuts

func migrateLegacyShortcut(
	newName: KeyboardShortcuts.Name,
	readLegacyCarbonValue: () -> (Int, Int)?
) {
	guard KeyboardShortcuts.getShortcut(for: newName) == nil else {
		return
	}

	guard let (carbonKeyCode, carbonModifiers) = readLegacyCarbonValue() else {
		return
	}

	KeyboardShortcuts.setShortcut(.init(carbonKeyCode: carbonKeyCode, carbonModifiers: carbonModifiers), for: newName)
}
```

## [ShortcutRecorder](https://github.com/Kentzo/ShortcutRecorder) migration

### Before

```swift
import ShortcutRecorder

recorderControl.bind(
	.objectValue,
	to: UserDefaultsController.shared,
	withKeyPath: "values.toggleMainWindow",
	options: [.valueTransformerName: NSValueTransformerName.keyedUnarchiveFromDataTransformerName]
)
```

### After

```swift
import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
	var body: some View {
		KeyboardShortcuts.Recorder("Toggle Main Window:", name: .toggleMainWindow)
	}
}
```

### Value migration

ShortcutRecorder projects often store archived shortcut values. Keep your existing decode logic and use the same `migrateLegacyShortcut` helper shown in the Magnet section above.

If your codebase uses older `SR*` type names, the migration is the same: decode the legacy value, extract carbon key code + modifiers, convert once.

## Rollout sequence

1. Migrate only when `KeyboardShortcuts.getShortcut(for:) == nil` to avoid overwriting user preferences.
2. Write with `KeyboardShortcuts.setShortcut`.
3. Remove the old stored value only after successful conversion.
4. Remove the old dependency.
