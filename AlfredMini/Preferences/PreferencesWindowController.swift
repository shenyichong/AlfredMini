import AppKit
import SwiftUI

final class PreferencesWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class PreferencesWindowController: NSObject, NSWindowDelegate {
    static let shared = PreferencesWindowController()
    private var window: PreferencesWindow?

    func show() {
        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showWindow()
        }
    }
    
    private func showWindow() {
        if window == nil {
            window = PreferencesWindow(contentRect: .init(x: 0, y: 0, width: 450, height: 250),
                                       styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window?.center()
            window?.title = "AlfredMini Preferences"
            window?.contentView = NSHostingView(rootView: PreferencesView())
            window?.isReleasedWhenClosed = false
            window?.delegate = self
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        window = nil
    }
}
