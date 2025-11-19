import AppKit

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let store = ClipboardStore.shared

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        statusItem.button?.title = "📋"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        guard let menu = statusItem.menu else { return }
        menu.removeAllItems()

        // Recent items (top 10)
        let recent = Array(store.items.prefix(10))
        if recent.isEmpty == false {
            for item in recent {
                let title = ellipsize(item.text.replacingOccurrences(of: "\n", with: " ⏎ "), max: 60)
                let mi = NSMenuItem(title: title, action: #selector(copyRecent(_:)), keyEquivalent: "")
                mi.target = self
                mi.representedObject = item.id
                menu.addItem(mi)
            }
            menu.addItem(NSMenuItem.separator())
        }

        let openItem = NSMenuItem(title: "Open Search", action: #selector(openSearch), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit AlfredMini", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func copyRecent(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID,
              let item = store.items.first(where: { $0.id == id }) else { return }
        store.copyToPasteboard(item: item)
    }

    @objc private func openSearch() {
        SearchPanelController.shared.show()
    }

    @objc private func openPreferences() {
        PreferencesWindowController.shared.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func ellipsize(_ s: String, max: Int) -> String {
        if s.count <= max { return s }
        let prefix = s.prefix(max - 1)
        return String(prefix) + "…"
    }
}


