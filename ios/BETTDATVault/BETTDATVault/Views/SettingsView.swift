import SwiftUI

struct SettingsView: View {
    @ObservedObject var auth: AuthenticationService
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var log = AccessLogService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var confirmWipeLog = false
    @State private var confirmEmergency = false

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.background.ignoresSafeArea()

                Form {
                    Section {
                        Toggle(isOn: $settingsStore.settings.requireFaceIDEveryOpen) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(auth.biometryTypeName) every open")
                                Text("Require authentication when returning to the app.")
                                    .font(.caption)
                                    .foregroundStyle(VaultTheme.textSecondary)
                            }
                        }
                        .tint(VaultTheme.accent)

                        Picker("Auto-lock", selection: $settingsStore.settings.autoLockInterval) {
                            ForEach(AutoLockInterval.allCases) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                        .tint(VaultTheme.accent)
                    } header: {
                        Text("Security")
                    } footer: {
                        Text("Immediate locks as soon as the app leaves the foreground. Longer intervals apply while the app stays open.")
                    }
                    .listRowBackground(VaultTheme.surface)

                    Section {
                        Button(role: .destructive) {
                            confirmWipeLog = true
                        } label: {
                            Label("Wipe access log", systemImage: "trash")
                        }
                        .listRowBackground(VaultTheme.surface)

                        Button(role: .destructive) {
                            confirmEmergency = true
                        } label: {
                            Label("Emergency lock", systemImage: "lock.rotation")
                        }
                        .listRowBackground(VaultTheme.surface)
                    } header: {
                        Text("Actions")
                    } footer: {
                        Text("Emergency lock immediately secures the vault and records an access event.")
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BETTDAT Vault")
                                .font(.headline)
                                .foregroundStyle(VaultTheme.textPrimary)
                            Text("@bettdat · BETTDAT LLC")
                                .font(.subheadline)
                                .foregroundStyle(VaultTheme.textSecondary)
                            Text("On-device encryption with CryptoKit. Keys stored in the iOS Keychain. No cloud, no analytics, no third-party SDKs.")
                                .font(.caption)
                                .foregroundStyle(VaultTheme.textSecondary)
                            Text("This app protects notes and files you store inside it. It does not secure Gmail, Stripe, Grok Bot, or any other external account.")
                                .font(.caption)
                                .foregroundStyle(VaultTheme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("About")
                    }
                    .listRowBackground(VaultTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(VaultTheme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(VaultTheme.accent)
                }
            }
            .confirmationDialog(
                "Wipe the entire access log?",
                isPresented: $confirmWipeLog,
                titleVisibility: .visible
            ) {
                Button("Wipe Log", role: .destructive) {
                    log.wipe()
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Emergency lock now?",
                isPresented: $confirmEmergency,
                titleVisibility: .visible
            ) {
                Button("Lock Now", role: .destructive) {
                    auth.emergencyLock()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .preferredColorScheme(.dark)
    }
}
