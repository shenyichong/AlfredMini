import SwiftUI
import KeyboardShortcuts

@main
struct AlfredMiniApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { Settings { PreferencesView() } }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController?
    private let clipboard = ClipboardMonitor()
    private let shortcuts = ShortcutsManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        PermissionsHelper.checkAccessibility()
        statusBar = StatusBarController()
        shortcuts.register()
        clipboard.start()
    }
}

