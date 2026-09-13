import SwiftUI

/// Solid privacy cover used while inactive/background so vault content
/// is not visible in the app switcher snapshot.
struct PrivacyOverlay: View {
    var body: some View {
        ZStack {
            VaultTheme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(VaultTheme.accentMuted)
                Text("BETTDAT Vault")
                    .font(.headline)
                    .foregroundStyle(VaultTheme.textSecondary)
            }
        }
    }
}
