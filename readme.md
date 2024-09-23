<div align="center">
	<img width="900" src="https://github.com/sindresorhus/KeyboardShortcuts/raw/main/logo-light.png#gh-light-mode-only" alt="KeyboardShortcuts">
	<img width="900" src="https://github.com/sindresorhus/KeyboardShortcuts/raw/main/logo-dark.png#gh-dark-mode-only" alt="KeyboardShortcuts">
	<br>
</div>

This package lets you add support for user-customizable global keyboard shortcuts to your macOS app in minutes. It's fully sandbox and Mac App Store compatible. And it's used in production by [Dato](https://sindresorhus.com/dato), [Jiffy](https://sindresorhus.com/jiffy), [Plash](https://github.com/sindresorhus/Plash), and [Lungo](https://sindresorhus.com/lungo).

I'm happy to accept more configurability and features. PR welcome! What you see here is just what I needed for my own apps.

<img src="https://github.com/sindresorhus/KeyboardShortcuts/raw/main/screenshot.png" width="532">

## Requirements

macOS 10.15+

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

`SettingsScreen.swift`

```swift
import SwiftUI
import KeyboardShortcuts

struct SettingsScreen: View {
	var body: some View {
		Form {
			KeyboardShortcuts.Recorder("Toggle Unicorn Mode:", name: .toggleUnicornMode)
		}
	}
}
```

*There's also [support for Cocoa](#cocoa) instead of SwiftUI.*

`KeyboardShortcuts.Recorder` takes care of storing the keyboard shortcut in `UserDefaults` and also warning the user if the chosen keyboard shortcut is already used by the system or the app's main menu.

Add a listener for when the user presses their chosen keyboard shortcut.

`App.swift`

```swift
import SwiftUI
import KeyboardShortcuts

@main
struct YourApp: App {
	@State private var appState = AppState()

	var body: some Scene {
		WindowGroup {
			// …
		}
		Settings {
			SettingsScreen()
		}
	}
}

@MainActor
@Observable
final class AppState {
	init() {
		KeyboardShortcuts.onKeyUp(for: .toggleUnicornMode) { [self] in
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

Using [`KeyboardShortcuts.RecorderCocoa`](Sources/KeyboardShortcuts/RecorderCocoa.swift) instead of `KeyboardShortcuts.Recorder`:

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

## Localization

This package supports [localizations](/Sources/KeyboardShortcuts/Localization). PR welcome for more!

1. Fork the repo.
2. Create a directory that has a name that uses an [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) language code and optional designators, followed by the `.lproj` suffix. [More here.](https://developer.apple.com/documentation/swift_packages/localizing_package_resources)
3. Create a file named `Localizable.strings` under the new language directory and then copy the contents of `KeyboardShortcuts/Localization/en.lproj/Localizable.strings` to the new file that you just created.
4. Localize and make sure to review your localization multiple times. Check for typos.
5. Try to find someone that speaks your language to review the translation.
6. Submit a PR.

## API

[See the API docs.](https://swiftpackageindex.com/sindresorhus/KeyboardShortcuts/documentation/keyboardshortcuts/keyboardshortcuts)

## Tips

#### Show a recorded keyboard shortcut in an `NSMenuItem`

<!-- TODO: Link to the docs instead when DocC supports showing type extensions. -->

See [`NSMenuItem#setShortcut`](https://github.com/sindresorhus/KeyboardShortcuts/blob/0dcedd56994d871f243f3d9c76590bfd9f8aba69/Sources/KeyboardShortcuts/NSMenuItem%2B%2B.swift#L14-L41).

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

#### Get all keyboard shortcuts

To get all the keyboard shortcut `Name`'s, conform `KeyboardShortcuts.Name` to `CaseIterable`.

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let foo = Self("foo")
	static let bar = Self("bar")
}

extension KeyboardShortcuts.Name: CaseIterable {
	public static let allCases: [Self] = [
		.foo,
		.bar
	]
}

// …

print(KeyboardShortcuts.Name.allCases)
```

And to get all the `Name`'s with a set keyboard shortcut:

```swift
print(KeyboardShortcuts.Name.allCases.filter { $0.shortcut != nil })
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
- Works when [`NSMenu` is open](https://github.com/sindresorhus/KeyboardShortcuts/issues/1) (e.g. menu bar apps).

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

#### Does it support media keys?

No, since it would not work for sandboxed apps. If your app is not sandboxed, you can use [`MediaKeyTap`](https://github.com/nhurden/MediaKeyTap).

#### Can you support CocoaPods or Carthage?

No. However, there is nothing stopping you from using Swift Package Manager for just this package even if you normally use CocoaPods or Carthage.

## Related

- [Defaults](https://github.com/sindresorhus/Defaults) - Swifty and modern UserDefaults
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) - Add "Launch at Login" functionality to your macOS app
- [More…](https://github.com/search?q=user%3Asindresorhus+language%3Aswift+archived%3Afalse&type=repositories)
