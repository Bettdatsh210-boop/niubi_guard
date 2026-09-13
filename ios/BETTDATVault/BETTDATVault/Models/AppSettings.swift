import Foundation

enum AutoLockInterval: String, Codable, CaseIterable, Identifiable {
    case immediate = "Immediate"
    case oneMinute = "1 minute"
    case fiveMinutes = "5 minutes"

    var id: String { rawValue }

    var seconds: TimeInterval? {
        switch self {
        case .immediate: return 0
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        }
    }
}

struct AppSettings: Codable, Equatable {
    /// Require Face ID (or passcode) every time the app opens / returns from background.
    var requireFaceIDEveryOpen: Bool
    var autoLockInterval: AutoLockInterval

    static let `default` = AppSettings(
        requireFaceIDEveryOpen: true,
        autoLockInterval: .immediate
    )
}
