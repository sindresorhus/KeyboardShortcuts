#if os(macOS)
import SwiftUI
import AppKit

/// A SwiftUI recorder view that supports binding-based recording of a single shortcut
/// or multi-chord sequences.
///
/// - Use `init(shortcut:option:)` to bind to a single `KeyboardShortcuts.Shortcut?`.
/// - Use `init(sequence:option:)` to bind to a `ShortcutSequence` and enable multi-chord
///   recording (for example, Ctrl-K Ctrl-S).
///
/// Example (multi-chord recording):
/// ```swift
/// @State private var sequence: ShortcutSequence = .init([])
///
/// var body: some View {
///     VStack(alignment: .leading) {
///         Text(sequence.presentableDescription)
///         ShortcutRecordView(
///             sequence: $sequence,
///             option: .init(enableSequences: true, maxSequenceLength: 2)
///         )
///     }
/// }
/// ```
///
/// Note: When `enableSequences` is `true`, the recorder can capture multi-chord
/// shortcuts like “Ctrl-K Ctrl-S”. Use `maxSequenceLength` to control the maximum
/// number of chords in the sequence.
public struct ShortcutRecordView: View {
	@Binding private var shortcuts: [KeyboardShortcuts.Shortcut]
	private let option: KeyboardShortcuts.RecorderOption

	public init(
		shortcut: Binding<KeyboardShortcuts.Shortcut?>,
		option: KeyboardShortcuts.RecorderOption = KeyboardShortcuts.RecorderOption()
	) {
		let sequenceBinding = Binding<ShortcutSequence>(
			get: { .init(shortcut.wrappedValue.map { [$0] } ?? []) },
			set: { sequence in
				shortcut.wrappedValue = sequence.shortcuts.first
			}
		)

		var option = option
		if option.enableSequences {
			assertionFailure("The `shortcut` binding does not support sequences. Please use the `sequence` binding instead.")
			option = .init(
				allowOnlyShiftModifier: option.allowOnlyShiftModifier,
				checkMenuCollision: option.checkMenuCollision,
				enableSequences: false,
				maxSequenceLength: 1
			)
		}

		self.init(sequence: sequenceBinding, option: option)
	}

	public init(
		sequence: Binding<ShortcutSequence>,
		option: KeyboardShortcuts.RecorderOption = KeyboardShortcuts.RecorderOption()
	) {
		self._shortcuts = Binding(
			get: { sequence.wrappedValue.shortcuts },
			set: { newShortcuts in
				sequence.wrappedValue.shortcuts = newShortcuts
			}
		)
		self.option = option
	}

	public var body: some View {
		BindingRecorder(shortcuts: $shortcuts, option: option)
	}
}

private struct BindingRecorder: NSViewRepresentable {
	typealias NSViewType = KeyboardShortcuts.RecorderCocoa

	@Binding var shortcuts: [KeyboardShortcuts.Shortcut]
	let option: KeyboardShortcuts.RecorderOption

	func makeNSView(context: Context) -> NSViewType {
		let view = KeyboardShortcuts.RecorderCocoa(
			get: { self.shortcuts },
			set: { self.shortcuts = $0 },
			option: option
		)
		return view
	}

		func updateNSView(_ nsView: NSViewType, context: Context) {
		}
}

// MARK: - Preview
#if DEBUG
struct ShortcutRecordView_Previews: PreviewProvider {
	private struct SingleShortcutWrapper: View {
		@State private var shortcut: KeyboardShortcuts.Shortcut? = .init(.a, modifiers: .command)

		var body: some View {
			VStack {
				Text("Recorded: \(shortcut?.description ?? "none")")
				ShortcutRecordView(shortcut: $shortcut)
			}
			.padding()
		}
	}

	private struct SequenceWrapper: View {
		@State private var sequence: ShortcutSequence = .init([
			.init(.k, modifiers: .control),
			.init(.s, modifiers: .control)
		])

		var body: some View {
			VStack {
				Text("Recorded: \(sequence.presentableDescription)")
				ShortcutRecordView(sequence: $sequence, option: .init(enableSequences: true, maxSequenceLength: 2))
			}
			.padding()
		}
	}

	static var previews: some View {
		VStack(spacing: 20) {
			SingleShortcutWrapper()
			SequenceWrapper()
		}
		.frame(width: 260)
	}
}
#endif
#endif
