import AppKit
import SwiftUI

final class SearchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class SearchPanelController: NSObject, NSWindowDelegate {
    static let shared = SearchPanelController()
    private var panel: SearchPanel?
    private var previouslyActiveApp: NSRunningApplication?

    func show() {
        if panel == nil {
            panel = SearchPanel(contentRect: .init(x: 0, y: 0, width: 640, height: 480),
                               styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel?.level = .screenSaver
            panel?.isFloatingPanel = true
            panel?.isOpaque = false
            panel?.backgroundColor = .clear
            panel?.hasShadow = true
            // hidesOnDeactivate must stay off: on macOS 14+ cooperative
            // activation can be denied while another app shows a modal
            // dialog, which would instantly hide the panel after showing it.
            panel?.hidesOnDeactivate = false
            panel?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel?.titleVisibility = .hidden
            panel?.titlebarAppearsTransparent = true
            panel?.delegate = self
            panel?.contentView = NSHostingView(rootView: SearchPanelView())
        }
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            previouslyActiveApp = frontmost
        }
        guard let panel, let screen = screenWithMouse() ?? NSScreen.main else { return }
        let frame = screen.visibleFrame
        panel.setFrameOrigin(.init(x: frame.midX - panel.frame.width/2, y: frame.midY - panel.frame.height/2))
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        // orderFrontRegardless puts the panel on screen even if the
        // activation request above is denied (e.g. a modal dialog is front).
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
    }

    private func screenWithMouse() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
    }

    var previouslyActiveAppPid: pid_t? { previouslyActiveApp?.processIdentifier }

    func toggle() { panel?.isVisible == true ? hide() : show() }
    func hide(restoreFocus: Bool = false) {
        guard panel?.isVisible == true else { return }
        panel?.orderOut(nil)
        // Deliberately no NSApp.hide(nil): hiding the whole app leaves it in
        // a hidden state that makes the next show() unreliable.
        guard restoreFocus, let app = previouslyActiveApp else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if #available(macOS 14.0, *) {
                NSApp.yieldActivation(to: app)
                app.activate()
            } else {
                app.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }
    func windowDidResignKey(_ notification: Notification) { hide() }
}
