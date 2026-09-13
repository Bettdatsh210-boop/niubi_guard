import SwiftUI

struct LockScreenView: View {
    @ObservedObject var auth: AuthenticationService
    @ObservedObject var log: AccessLogService
    @State private var isAuthenticating = false
    @State private var statusMessage: String?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ZStack {
            VaultTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56, weight: .ultraLight))
                        .foregroundStyle(VaultTheme.accent)
                        .accessibilityHidden(true)

                    Text("BETTDAT Vault")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(VaultTheme.textPrimary)

                    Text("@bettdat")
                        .font(.subheadline)
                        .foregroundStyle(VaultTheme.textSecondary)
                }

                Spacer().frame(height: 48)

                Button {
                    Task { await authenticate() }
                } label: {
                    HStack(spacing: 10) {
                        if isAuthenticating {
                            ProgressView()
                                .tint(VaultTheme.background)
                        } else {
                            Image(systemName: "faceid")
                                .font(.title3)
                        }
                        Text(isAuthenticating ? "Authenticating…" : "Unlock with \(auth.biometryTypeName)")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(VaultTheme.accent)
                    .foregroundStyle(VaultTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isAuthenticating)
                .padding(.horizontal, 32)

                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(VaultTheme.danger)
                        .padding(.top, 16)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                if let failed = log.lastFailedAttempt {
                    VStack(spacing: 4) {
                        Text("Last failed attempt")
                            .font(.caption2)
                            .foregroundStyle(VaultTheme.textSecondary)
                        Text(dateFormatter.string(from: failed.timestamp))
                            .font(.caption)
                            .foregroundStyle(VaultTheme.textSecondary)
                    }
                    .padding(.bottom, 32)
                } else {
                    Text("On-device vault · Face ID protected")
                        .font(.caption)
                        .foregroundStyle(VaultTheme.textSecondary.opacity(0.7))
                        .padding(.bottom, 32)
                }
            }
        }
        .task {
            // Offer unlock promptly when the lock screen appears.
            await authenticate()
        }
    }

    private func authenticate() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        statusMessage = nil
        let result = await auth.unlock()
        isAuthenticating = false
        switch result {
        case .success:
            statusMessage = nil
        case .cancelled:
            statusMessage = nil
        case .failed(let message):
            statusMessage = message
        case .unavailable(let message):
            statusMessage = message
        }
    }
}
