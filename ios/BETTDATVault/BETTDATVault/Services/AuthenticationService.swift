import Foundation
import LocalAuthentication

enum AuthResult {
    case success
    case failed(String)
    case cancelled
    case unavailable(String)
}

@MainActor
final class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()

    @Published private(set) var isUnlocked = false
    @Published private(set) var biometryTypeName = "Face ID"
    @Published private(set) var canUseBiometrics = false

    /// Tracks last unlock time for auto-lock timers.
    private(set) var lastUnlockDate: Date?

    private init() {
        refreshBiometryAvailability()
    }

    func refreshBiometryAvailability() {
        let context = LAContext()
        var error: NSError?
        canUseBiometrics = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        switch context.biometryType {
        case .faceID:
            biometryTypeName = "Face ID"
        case .touchID:
            biometryTypeName = "Touch ID"
        case .opticID:
            biometryTypeName = "Optic ID"
        default:
            biometryTypeName = "Device Passcode"
        }
    }

    /// Authenticates with Face ID / biometrics, falling back to device passcode.
    func unlock(reason: String = "Unlock BETTDAT Vault") async -> AuthResult {
        refreshBiometryAvailability()
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        // Prefer biometrics; if unavailable, deviceOwnerAuthentication allows passcode.
        let policy: LAPolicy = .deviceOwnerAuthentication

        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            let message = error?.localizedDescription ?? "Authentication unavailable"
            AccessLogService.shared.append(.unlockFailed, detail: message)
            return .unavailable(message)
        }

        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            if success {
                isUnlocked = true
                lastUnlockDate = Date()
                AccessLogService.shared.append(.unlockSuccess, detail: biometryTypeName)
                return .success
            } else {
                AccessLogService.shared.append(.unlockFailed, detail: "Authentication returned false")
                return .failed("Authentication failed")
            }
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                return .cancelled
            default:
                AccessLogService.shared.append(.unlockFailed, detail: laError.localizedDescription)
                return .failed(laError.localizedDescription)
            }
        } catch {
            AccessLogService.shared.append(.unlockFailed, detail: error.localizedDescription)
            return .failed(error.localizedDescription)
        }
    }

    func lock(reason: AccessEventType = .lock) {
        guard isUnlocked else { return }
        isUnlocked = false
        lastUnlockDate = nil
        AccessLogService.shared.append(reason)
    }

    func emergencyLock() {
        isUnlocked = false
        lastUnlockDate = nil
        AccessLogService.shared.append(.emergencyLock)
    }

    /// Whether the vault should re-lock based on settings + elapsed time.
    func shouldAutoLock(settings: AppSettings) -> Bool {
        guard isUnlocked else { return false }
        if settings.requireFaceIDEveryOpen {
            // Immediate re-auth whenever returning from background is handled by scene phase;
            // this covers idle timeout while remaining in foreground.
        }
        guard let interval = settings.autoLockInterval.seconds else { return false }
        if interval == 0 {
            // Immediate means lock as soon as we leave the active scene (handled externally).
            return false
        }
        guard let last = lastUnlockDate else { return true }
        return Date().timeIntervalSince(last) >= interval
    }
}
