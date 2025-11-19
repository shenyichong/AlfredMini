import AppKit
import SwiftUI

final class SearchPanelController: NSObject, NSWindowDelegate {
    static let shared = SearchPanelController()

    private var window: NSPanel?

    func show() {
        if window == nil {
            let hosting = NSHostingView(rootView: SearchPanelView())
            let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
                                styleMask: [.titled, .nonactivatingPanel, .fullSizeContentView],
                                backing: .buffered, defer: false)
            panel.level = .statusBar
            panel.isFloatingPanel = true
            panel.isOpaque = false
            panel.backgroundColor = .clear // Ensure transparent for VisualEffectView
            panel.hasShadow = true
            panel.hidesOnDeactivate = true
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.delegate = self
            panel.contentView = hosting
            window = panel
        }
        if let window = window {
            positionCenter(window)
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    func toggle() {
        if let window = window, window.isVisible { hide() } else { show() }
    }

    func hide() { window?.orderOut(nil) }

    func windowDidResignKey(_ notification: Notification) { hide() }

    private func positionCenter(_ window: NSWindow) {
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let size = window.frame.size
            let origin = CGPoint(x: frame.midX - size.width/2, y: frame.midY - size.height/2)
            window.setFrame(NSRect(origin: origin, size: size), display: true)
        }
    }
}


