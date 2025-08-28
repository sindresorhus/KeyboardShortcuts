#if os(macOS)
import SwiftUI
  import AppKit

public struct ShortcutRecordView: View {
  @Binding var shortcut: KeyboardShortcuts.Shortcut?

  public init(shortcut: Binding<KeyboardShortcuts.Shortcut?>) {
    self._shortcut = shortcut
  }

  public var body: some View {
    BindingRecorder(shortcut: $shortcut)
  }
}

private struct BindingRecorder: NSViewRepresentable {
  typealias NSViewType = KeyboardShortcuts.RecorderCocoa

  @Binding var shortcut: KeyboardShortcuts.Shortcut?

  func makeNSView(context: Context) -> NSViewType {
    let view = KeyboardShortcuts.RecorderCocoa(
      get: { self.shortcut },
      set: { self.shortcut = $0 }
    )
    return view
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {
    nsView.syncDisplayedShortcutFromSource()
  }
}

// MARK: - Preview
#if DEBUG
struct ShortcutRecordView_Previews: PreviewProvider {
  private struct Wrapper: View {
    @State private var shortcut: KeyboardShortcuts.Shortcut? = nil
    var body: some View {
      ShortcutRecordView(shortcut: $shortcut)
        .padding()
        .frame(width: 240)
    }
  }

  static var previews: some View {
    Wrapper()
      .frame(width: 260)
  }
}
#endif
#endif
