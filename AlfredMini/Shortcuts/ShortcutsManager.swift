import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let showSearch = Self("showSearch")
    static let quickPin = Self("quickPin")
}

final class ShortcutsManager {
    func register() {
        if KeyboardShortcuts.getShortcut(for: .showSearch) == nil {
            KeyboardShortcuts.setShortcut(.init(.space, modifiers: [.option]), for: .showSearch)
        }
        if KeyboardShortcuts.getShortcut(for: .quickPin) == nil {
            KeyboardShortcuts.setShortcut(.init(.s, modifiers: [.control, .option]), for: .quickPin)
        }

        KeyboardShortcuts.onKeyDown(for: .showSearch) { SearchPanelController.shared.toggle() }
        KeyboardShortcuts.onKeyDown(for: .quickPin) { ClipboardStore.shared.pinCurrentClipboardIfText() }
    }
}


