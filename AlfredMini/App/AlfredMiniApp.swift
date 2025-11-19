import SwiftUI
import AppKit
import KeyboardShortcuts

@main
struct AlfredMiniApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private let clipboardMonitor = ClipboardMonitor()
    private let shortcutsManager = ShortcutsManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        shortcutsManager.register()
        clipboardMonitor.start()
    }
}


