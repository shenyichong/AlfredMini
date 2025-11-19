import SwiftUI
import KeyboardShortcuts

struct PreferencesView: View {
    @ObservedObject private var store = ClipboardStore.shared
    @State private var retention: Double = 500

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Shortcuts").font(.headline)
                HStack {
                    Text("Show Search:")
                    KeyboardShortcuts.Recorder(for: .showSearch)
                }
                HStack {
                    Text("Quick Pin:")
                    KeyboardShortcuts.Recorder(for: .quickPin)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Retention").font(.headline)
                HStack {
                    Text("Max items: \(Int(retention))")
                    Slider(value: $retention, in: 50...2000, step: 50)
                }
            }
        }
        .padding(20)
        .frame(width: 480)
        .onAppear {
            retention = Double(store.retentionLimit)
        }
        .onChange(of: retention) { newValue in
            store.retentionLimit = Int(newValue)
        }
    }
}
