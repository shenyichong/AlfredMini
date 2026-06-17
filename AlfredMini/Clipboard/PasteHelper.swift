import ApplicationServices

enum PasteHelper {
    static func paste(toPid pid: pid_t? = nil) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        let cmd: CGKeyCode = 0x37, v: CGKeyCode = 0x09

        let events = [
            CGEvent(keyboardEventSource: source, virtualKey: cmd, keyDown: true),
            CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: true),
            CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: false),
            CGEvent(keyboardEventSource: source, virtualKey: cmd, keyDown: false)
        ]
        events.forEach { event in
            event?.flags = .maskCommand
            if let pid {
                event?.postToPid(pid)
            } else {
                event?.post(tap: .cghidEventTap)
            }
        }
    }
}
