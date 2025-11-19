import AppKit
import SwiftUI

// Custom window subclass to ensure it can become key/main
// This is critical for LSUIElement (menubar) apps to accept keyboard input
final class PreferencesWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class PreferencesWindowController: NSObject, NSWindowDelegate {
    static let shared = PreferencesWindowController()

    private var window: NSWindow?

    func show() {
        // Temporarily switch to regular app mode to ensure the window gets focus
        NSApp.setActivationPolicy(.regular)
        
        // Small delay to allow policy change to propagate before showing window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            if self.window == nil {
                let rootView = PreferencesView()
                let hosting = NSHostingView(rootView: rootView)
                
                let newWindow = PreferencesWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 450, height: 250),
                    styleMask: [.titled, .closable, .miniaturizable],
                    backing: .buffered,
                    defer: false
                )
                newWindow.center()
                newWindow.title = "AlfredMini Preferences"
                newWindow.contentView = hosting
                newWindow.isReleasedWhenClosed = false
                newWindow.delegate = self
                self.window = newWindow
            }
            
            NSApp.activate(ignoringOtherApps: true)
            self.window?.makeKeyAndOrderFront(nil)
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        // Revert to accessory mode (menubar only) when window closes
        NSApp.setActivationPolicy(.accessory)
        window = nil // Release the window
    }
}
