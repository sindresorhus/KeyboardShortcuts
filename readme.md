<div align="center">
	<img width="900" src="https://github.com/sindresorhus/KeyboardShortcuts/raw/main/logo.png" alt="KeyboardShortcuts">
	<br>
</div>

This package lets you add support for user-customizable global keyboard shortcuts to your macOS app in minutes. It's fully sandbox and Mac App Store compatible. And it's used in production by [Dato](https://sindresorhus.com/dato), [Jiffy](https://sindresorhus.com/jiffy), [Plash](https://github.com/sindresorhus/Plash), and [Lungo](https://sindresorhus.com/lungo).

I'm happy to accept more configurability and features. PR welcome! What you see here is just what I needed for my own apps.

<img src="https://github.com/sindresorhus/KeyboardShortcuts/raw/main/screenshot.png" width="532">

## Requirements

macOS 10.11+

## Install

Add `https://github.com/sindresorhus/KeyboardShortcuts` in the [“Swift Package Manager” tab in Xcode](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

## Usage

First, register a name for the keyboard shortcut.

`Constants.swift`

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let toggleUnicornMode = Self("toggleUnicornMode")
}
```

You can then refer to this strongly-typed name in other places.

You will want to make a view where the user can choose a keyboard shortcut.

`PreferencesView.swift`

```swift
import SwiftUI
import KeyboardShortcuts

struct PreferencesView: View {
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			Text("Toggle Unicorn Mode:")
			KeyboardShortcuts.Recorder(for: .toggleUnicornMode)
		}
	}
}
```

*There's also [support for Cocoa](#cocoa) instead of SwiftUI.*

`KeyboardShortcuts.Recorder` takes care of storing the keyboard shortcut in `UserDefaults` and also warning the user if the chosen keyboard shortcut is already used by the system or the app's main menu.

Add a listener for when the user presses their chosen keyboard shortcut.

`AppDelegate.swift`

```swift
import Cocoa
import KeyboardShortcuts

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(_ notification: Notification) {
		KeyboardShortcuts.onKeyUp(for: .toggleUnicornMode) { [self] in
			// The user pressed the keyboard shortcut for “unicorn mode”!
			isUnicornMode.toggle()
		}
	}
}
```

*You can also listen to key down with `.onKeyDown()`*

**That's all! ✨**

You can find a complete example in the “Example” directory.

You can also find a [real-world example](https://github.com/sindresorhus/Plash/blob/b348a62645a873abba8dc11ff0fb8fe423419411/Plash/PreferencesView.swift#L121-L130) in my Plash app.

#### Cocoa

Use [`KeyboardShortcuts.RecorderCocoa`](Sources/KeyboardShortcuts/RecorderCocoa.swift) instead of `KeyboardShortcuts.Recorder`.

```swift
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

## Localization

This package supports [localizations](/Sources/KeyboardShortcuts/Localization). PR welcome for more!

1. Fork the repo.
2. Create a directory that has a name that uses an ISO 639 language code and optional designators, followed by the `.lproj` suffix. [More here.](https://developer.apple.com/documentation/swift_packages/localizing_package_resources)
3. Create a file named `Localizable.strings` under the new language directory and then copy the contents of `KeyboardShortcuts/Localization/en.lproj/Localizable.strings` to the new file that you just created.
4. Localize and make sure to review your localization multiple times. Check for typos.
5. Try to find someone that speaks your language to review the translation.
6. Submit a PR.

## API

[See the API docs.](https://sindresorhus.com/KeyboardShortcuts/Enums/KeyboardShortcuts.html)

## Tips

#### Show a recorded keyboard shortcut in an `NSMenuItem`

See [`NSMenuItem#setShortcut`](https://sindresorhus.com/KeyboardShortcuts/Extensions/NSMenuItem.html).

#### Dynamic keyboard shortcuts

Your app might need to support keyboard shortcuts for user-defined actions. Normally, you would statically register the keyboard shortcuts upfront in `extension KeyboardShortcuts.Name {}`. However, this is not a requirement. It's only for convenience so that you can use dot-syntax when calling various APIs (for example, `.onKeyDown(.unicornMode) {}`). You can create `KeyboardShortcut.Name`'s dynamically and store them yourself. You can see this in action in the example project.

#### Default keyboard shortcuts

Setting a default keyboard shortcut can be useful if you're migrating from a different package or just making something for yourself. However, please do not set this for a publicly distributed app. Users find it annoying when random apps steal their existing keyboard shortcuts. It’s generally better to show a welcome screen on the first app launch that lets the user set the shortcut.

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleUnicornMode = Self("toggleUnicornMode", default: .init(.k, modifiers: [.command, .option]))
}
```

## FAQ

#### How is it different from [`MASShortcut`](https://github.com/shpakovski/MASShortcut)?

This package:
- Written in Swift with a swifty API.
- More native-looking UI component.
- SwiftUI component included.
- Support for listening to key down, not just key up.
- Swift Package Manager support.
- Connect a shortcut to an `NSMenuItem`.

`MASShortcut`:
- More mature.
- More localizations.

#### How is it different from [`HotKey`](https://github.com/soffes/HotKey)?

`HotKey` is good for adding hard-coded keyboard shortcuts, but it doesn't provide any UI component for the user to choose their own keyboard shortcuts.

#### Why is this package importing `Carbon`? Isn't that deprecated?

Most of the Carbon APIs were deprecated years ago, but there are some left that Apple never shipped modern replacements for. This includes registering global keyboard shortcuts. However, you should not need to worry about this. Apple will for sure ship new APIs before deprecating the Carbon APIs used here.

#### Does this package cause any permission dialogs?

No.

#### How can I add an app-specific keyboard shortcut that is only active when the app is?

That is outside the scope of this package. You can either use [`NSEvent.addLocalMonitorForEvents`](https://developer.apple.com/documentation/appkit/nsevent/1534971-addlocalmonitorforevents), [`NSMenuItem` with keyboard shortcut](https://developer.apple.com/documentation/appkit/nsmenuitem/2880316-allowskeyequivalentwhenhidden) (it can even be hidden), or SwiftUI's [`View#keyboardShortcut()` modifier](https://developer.apple.com/documentation/swiftui/form/keyboardshortcut(_:)).

#### Can you support CocoaPods or Carthage?

No. However, there is nothing stopping you from using Swift Package Manager for just this package even if you normally use CocoaPods or Carthage.

## Related

- [Defaults](https://github.com/sindresorhus/Defaults) - Swifty and modern UserDefaults
- [Regex](https://github.com/sindresorhus/Regex) - Swifty regular expressions
- [Preferences](https://github.com/sindresorhus/Preferences) - Add a preferences window to your macOS app in minutes
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) - Add "Launch at Login" functionality to your macOS app
- [More…](https://github.com/search?q=user%3Asindresorhus+language%3Aswift)
