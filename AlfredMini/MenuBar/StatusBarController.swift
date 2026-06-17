import AppKit

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let store = ClipboardStore.shared

    override init() {
        super.init()
        if let icon = NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "AlfredMini") {
            icon.isTemplate = true
            statusItem.button?.image = icon
        } else {
            statusItem.button?.title = "📋"
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        
        for item in store.items.prefix(10) {
            let title = item.text.replacingOccurrences(of: "\n", with: " ⏎ ").prefix(60)
            let mi = NSMenuItem(title: String(title) + (item.text.count > 60 ? "…" : ""), action: #selector(copyRecent), keyEquivalent: "")
            mi.target = self
            mi.representedObject = item.id
            menu.addItem(mi)
        }
        
        if !store.items.isEmpty { menu.addItem(.separator()) }
        menu.addItem(menuItem("Open Search", #selector(openSearch)))
        menu.addItem(menuItem("Preferences…", #selector(openPreferences), ","))
        menu.addItem(.separator())
        menu.addItem(menuItem("Quit AlfredMini", #selector(quit), "q"))
    }
    
    private func menuItem(_ title: String, _ action: Selector, _ key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func copyRecent(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID,
              let item = store.items.first(where: { $0.id == id }) else { return }
        store.copyToPasteboard(item: item)
    }

    @objc private func openSearch() { SearchPanelController.shared.show() }
    @objc private func openPreferences() { PreferencesWindowController.shared.show() }
    @objc private func quit() { NSApp.terminate(nil) }
}

