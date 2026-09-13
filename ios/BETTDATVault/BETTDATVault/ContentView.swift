import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: AuthenticationService
    @EnvironmentObject private var store: VaultStore
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        Group {
            if auth.isUnlocked {
                VaultHomeView(store: store, auth: auth)
            } else {
                LockScreenView(auth: auth, log: AccessLogService.shared)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: auth.isUnlocked)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService.shared)
        .environmentObject(VaultStore.shared)
        .environmentObject(SettingsStore.shared)
        .preferredColorScheme(.dark)
}
