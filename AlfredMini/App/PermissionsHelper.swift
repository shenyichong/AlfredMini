import ApplicationServices

enum PermissionsHelper {
    static func checkAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as NSDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }
}
