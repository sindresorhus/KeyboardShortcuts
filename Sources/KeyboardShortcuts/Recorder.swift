#if os(macOS)
import SwiftUI

extension KeyboardShortcuts {
	enum ShortcutSource {
		case name(Name)
		case binding(Binding<Shortcut?>)

		var binding: Binding<Shortcut?>? {
			if case .binding(let binding) = self { binding } else { nil }
		}
	}

	private struct _Recorder: NSViewRepresentable { // swiftlint:disable:this type_name
		typealias NSViewType = RecorderCocoa

		let source: ShortcutSource
		let onChange: ((_ shortcut: Shortcut?) -> Void)?

		final class Coordinator {
			var shortcutBinding: Binding<Shortcut?>?
			var onChange: ((_ shortcut: Shortcut?) -> Void)?

			init(
				shortcutBinding: Binding<Shortcut?>?,
				onChange: ((_ shortcut: Shortcut?) -> Void)?
			) {
				self.shortcutBinding = shortcutBinding
				self.onChange = onChange
			}

			func handleChange(_ shortcut: Shortcut?) {
				shortcutBinding?.wrappedValue = shortcut
				onChange?(shortcut)
			}
		}

		func makeCoordinator() -> Coordinator {
			.init(shortcutBinding: source.binding, onChange: onChange)
		}

		func makeNSView(context: Context) -> NSViewType {
			let coordinator = context.coordinator

			switch source {
			case .name(let name):
				return .init(for: name) { shortcut in
					coordinator.handleChange(shortcut)
				}
			case .binding(let binding):
				return .init(shortcut: binding.wrappedValue) { shortcut in
					coordinator.handleChange(shortcut)
				}
			}
		}

		func updateNSView(_ nsView: NSViewType, context: Context) {
			let coordinator = context.coordinator
			coordinator.onChange = onChange

			switch source {
			case .name(let name):
				nsView.shortcutName = name
			case .binding(let binding):
				coordinator.shortcutBinding = binding

				guard nsView.shortcut != binding.wrappedValue else {
					return
				}

				nsView.shortcut = binding.wrappedValue
			}
		}
	}

	/**
	A SwiftUI `View` that lets the user record a keyboard shortcut.

	You would usually put this in your settings window.

	It automatically prevents choosing a keyboard shortcut that is already taken by the system or by the app's main menu by showing a user-friendly alert to the user.

	It takes care of storing the keyboard shortcut in `UserDefaults` for you when initialized with a name. When initialized with a binding, it reads and writes the shortcut through the binding.

	- Note: When initialized with a binding, the shortcut is not automatically registered as a global hotkey. You are responsible for storing and handling the shortcut yourself.

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

	- Note: Since macOS 15, for sandboxed apps, it's [no longer possible](https://developer.apple.com/forums/thread/763878?answerId=804374022#804374022) to specify the `Option` key without also using `Command` or `Control`.
	*/
	public struct Recorder<Label: View>: View { // swiftlint:disable:this type_name
		private let shortcutSource: ShortcutSource
		private let onChange: ((Shortcut?) -> Void)?
		private let hasLabel: Bool
		private let label: Label

		private init(
			shortcutSource: ShortcutSource,
			onChange: ((Shortcut?) -> Void)? = nil,
			hasLabel: Bool,
			@ViewBuilder label: () -> Label
		) {
			self.shortcutSource = shortcutSource
			self.onChange = onChange
			self.hasLabel = hasLabel
			self.label = label()
		}

		public var body: some View {
			if hasLabel {
				if #available(macOS 13, *) {
					LabeledContent {
						recorderView
					} label: {
						label
					}
				} else {
					recorderView
						.formLabel {
							label
						}
				}
			} else {
				recorderView
			}
		}

		private var recorderView: some View {
			_Recorder(
				source: shortcutSource,
				onChange: onChange
			)
		}
	}
}

extension KeyboardShortcuts.Recorder<EmptyView> {
	/**
	- Parameter name: Strongly-typed keyboard shortcut name.
	- Parameter onChange: Callback which will be called when the keyboard shortcut is changed/removed by the user. This can be useful when you need more control. For example, when migrating from a different keyboard shortcut solution and you need to store the keyboard shortcut somewhere yourself instead of relying on the built-in storage. However, it's strongly recommended to just rely on the built-in storage when possible.
	*/
	public init(
		for name: KeyboardShortcuts.Name,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
	) {
		self.init(
			shortcutSource: .name(name),
			onChange: onChange,
			hasLabel: false
		) {}
	}

	/**
	Creates a keyboard shortcut recorder that reads and writes to a binding.

	Use this initializer when you want to manage the shortcut storage yourself instead of using the built-in `UserDefaults` storage. The shortcut is not automatically registered as a global hotkey — you are responsible for storing and handling the shortcut yourself.

	- Parameter shortcut: The keyboard shortcut binding to read and write.
	- Parameter onChange: Callback which will be called when the keyboard shortcut is changed/removed by the user.
	*/
	public init(
		shortcut: Binding<KeyboardShortcuts.Shortcut?>,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
	) {
		self.init(
			shortcutSource: .binding(shortcut),
			onChange: onChange,
			hasLabel: false
		) {}
	}
}

extension KeyboardShortcuts.Recorder<Text> {
	private init(
		_ title: Text,
		source: KeyboardShortcuts.ShortcutSource,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)?
	) {
		self.init(
			shortcutSource: source,
			onChange: onChange,
			hasLabel: true
		) {
			title
		}
	}

	/**
	- Parameter title: The title of the keyboard shortcut recorder, describing its purpose.
	- Parameter name: Strongly-typed keyboard shortcut name.
	- Parameter onChange: Callback which will be called when the keyboard shortcut is changed/removed by the user. This can be useful when you need more control. For example, when migrating from a different keyboard shortcut solution and you need to store the keyboard shortcut somewhere yourself instead of relying on the built-in storage. However, it's strongly recommended to just rely on the built-in storage when possible.
	*/
	public init(
		_ title: LocalizedStringKey,
		name: KeyboardShortcuts.Name,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
	) {
		self.init(Text(title), source: .name(name), onChange: onChange)
	}

	/**
	- Parameter title: The title of the keyboard shortcut recorder, describing its purpose.
	- Parameter name: Strongly-typed keyboard shortcut name.
	- Parameter onChange: Callback which will be called when the keyboard shortcut is changed/removed by the user. This can be useful when you need more control. For example, when migrating from a different keyboard shortcut solution and you need to store the keyboard shortcut somewhere yourself instead of relying on the built-in storage. However, it's strongly recommended to just rely on the built-in storage when possible.
	*/
	@_disfavoredOverload
	public init(
		_ title: String,
		name: KeyboardShortcuts.Name,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
	) {
		self.init(Text(title), source: .name(name), onChange: onChange)
	}

	/**
	Creates a keyboard shortcut recorder that reads and writes to a binding.

	Use this initializer when you want to manage the shortcut storage yourself instead of using the built-in `UserDefaults` storage. The shortcut is not automatically registered as a global hotkey — you are responsible for storing and handling the shortcut yourself.

	- Parameter title: The title of the keyboard shortcut recorder, describing its purpose.
	- Parameter shortcut: The keyboard shortcut binding to read and write.
	- Parameter onChange: Callback which will be called when the keyboard shortcut is changed/removed by the user.
	*/
	public init(
		_ title: LocalizedStringKey,
		shortcut: Binding<KeyboardShortcuts.Shortcut?>,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
	) {
		self.init(Text(title), source: .binding(shortcut), onChange: onChange)
	}

	/**
	Creates a keyboard shortcut recorder that reads and writes to a binding.

	Use this initializer when you want to manage the shortcut storage yourself instead of using the built-in `UserDefaults` storage. The shortcut is not automatically registered as a global hotkey — you are responsible for storing and handling the shortcut yourself.

	- Parameter title: The title of the keyboard shortcut recorder, describing its purpose.
	- Parameter shortcut: The keyboard shortcut binding to read and write.
	- Parameter onChange: Callback which will be called when the keyboard shortcut is changed/removed by the user.
	*/
	@_disfavoredOverload
	public init(
		_ title: String,
		shortcut: Binding<KeyboardShortcuts.Shortcut?>,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
	) {
		self.init(Text(title), source: .binding(shortcut), onChange: onChange)
	}
}

extension KeyboardShortcuts.Recorder {
	/**
	- Parameter name: Strongly-typed keyboard shortcut name.
	- Parameter onChange: Callback which will be called when the keyboard shortcut is changed/removed by the user. This can be useful when you need more control. For example, when migrating from a different keyboard shortcut solution and you need to store the keyboard shortcut somewhere yourself instead of relying on the built-in storage. However, it's strongly recommended to just rely on the built-in storage when possible.
	- Parameter label: A view that describes the purpose of the keyboard shortcut recorder.
	*/
	public init(
		for name: KeyboardShortcuts.Name,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil,
		@ViewBuilder label: () -> Label
	) {
		self.init(
			shortcutSource: .name(name),
			onChange: onChange,
			hasLabel: true,
			label: label
		)
	}

	/**
	Creates a keyboard shortcut recorder that reads and writes to a binding.

	Use this initializer when you want to manage the shortcut storage yourself instead of using the built-in `UserDefaults` storage. The shortcut is not automatically registered as a global hotkey — you are responsible for storing and handling the shortcut yourself.

	- Parameter shortcut: The keyboard shortcut binding to read and write.
	- Parameter onChange: Callback which will be called when the keyboard shortcut is changed/removed by the user.
	- Parameter label: A view that describes the purpose of the keyboard shortcut recorder.
	*/
	public init(
		shortcut: Binding<KeyboardShortcuts.Shortcut?>,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil,
		@ViewBuilder label: () -> Label
	) {
		self.init(
			shortcutSource: .binding(shortcut),
			onChange: onChange,
			hasLabel: true,
			label: label
		)
	}
}

#Preview {
	KeyboardShortcuts.Recorder("record_shortcut", name: .init("xcodePreview"))
		.environment(\.locale, .init(identifier: "en"))
}

#Preview {
	KeyboardShortcuts.Recorder("record_shortcut", name: .init("xcodePreview"))
		.environment(\.locale, .init(identifier: "zh-Hans"))
}

#Preview {
	KeyboardShortcuts.Recorder("record_shortcut", name: .init("xcodePreview"))
		.environment(\.locale, .init(identifier: "ru"))
}
#endif
