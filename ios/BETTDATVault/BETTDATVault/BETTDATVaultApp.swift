import SwiftUI

@main
struct BETTDATVaultApp: App {
    @StateObject private var auth = AuthenticationService.shared
    @StateObject private var store = VaultStore.shared
    @StateObject private var settingsStore = SettingsStore.shared
    @StateObject private var accessLog = AccessLogService.shared

    @Environment(\.scenePhase) private var scenePhase

    /// Shown while inactive/background to hide vault content from app-switcher snapshots.
    @State private var showPrivacyCover = false

    /// Idle auto-lock timer (1 min / 5 min).
    @State private var autoLockTask: Task<Void, Never>?

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(auth)
                    .environmentObject(store)
                    .environmentObject(settingsStore)
                    .environmentObject(accessLog)
                    .preferredColorScheme(.dark)
                    .task {
                        try? store.prepare()
                        accessLog.reloadEncryptedLog()
                    }

                if showPrivacyCover {
                    PrivacyOverlay()
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhase(newPhase)
            }
            .onChange(of: auth.isUnlocked) { _, unlocked in
                if unlocked {
                    scheduleAutoLockIfNeeded()
                } else {
                    autoLockTask?.cancel()
                    autoLockTask = nil
                }
            }
            .onChange(of: settingsStore.settings.autoLockInterval) { _, _ in
                if auth.isUnlocked {
                    scheduleAutoLockIfNeeded()
                }
            }
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            withAnimation(.easeOut(duration: 0.15)) {
                showPrivacyCover = false
            }
            // Re-lock / re-auth when returning if configured.
            if settingsStore.settings.requireFaceIDEveryOpen && auth.isUnlocked == false {
                // Already locked — lock screen will prompt.
            } else if settingsStore.settings.requireFaceIDEveryOpen {
                // Require Face ID every open: lock when returning from background.
                // (We locked on background below when requireFaceIDEveryOpen or immediate.)
            }

            if auth.isUnlocked {
                if auth.shouldAutoLock(settings: settingsStore.settings) {
                    auth.lock(reason: .autoLock)
                } else {
                    scheduleAutoLockIfNeeded()
                }
            }

        case .inactive:
            // Cover content immediately so the snapshot is blank/locked branding.
            withAnimation(.easeIn(duration: 0.1)) {
                showPrivacyCover = true
            }

        case .background:
            withAnimation(.easeIn(duration: 0.1)) {
                showPrivacyCover = true
            }
            autoLockTask?.cancel()
            autoLockTask = nil

            let settings = settingsStore.settings
            if auth.isUnlocked {
                if settings.requireFaceIDEveryOpen || settings.autoLockInterval == .immediate {
                    auth.lock(reason: .backgroundLock)
                } else if auth.shouldAutoLock(settings: settings) {
                    auth.lock(reason: .autoLock)
                }
                // For 1/5 min intervals, leave unlocked only if still within window;
                // will check again on active.
            }

        @unknown default:
            break
        }
    }

    private func scheduleAutoLockIfNeeded() {
        autoLockTask?.cancel()
        let settings = settingsStore.settings
        guard let seconds = settings.autoLockInterval.seconds, seconds > 0 else {
            return
        }
        autoLockTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            if auth.isUnlocked {
                auth.lock(reason: .autoLock)
            }
        }
    }
}
