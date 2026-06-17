import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // Defaults only apply when the user hasn't recorded a shortcut in
    // Preferences — unlike setShortcut(), they never clobber a custom binding.
    static let showSearch = Self("showSearch", default: .init(.k, modifiers: [.command]))
    static let quickPin = Self("quickPin", default: .init(.s, modifiers: [.control, .option]))
}

final class ShortcutsManager {
    func register() {
        KeyboardShortcuts.onKeyDown(for: .showSearch) { SearchPanelController.shared.toggle() }
        KeyboardShortcuts.onKeyDown(for: .quickPin) { ClipboardStore.shared.pinCurrentClipboard() }
    }
}

