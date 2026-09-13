import SwiftUI

struct AccessLogView: View {
    @ObservedObject var log: AccessLogService
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.background.ignoresSafeArea()

                if log.entries.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundStyle(VaultTheme.accentMuted)
                        Text("No access events yet")
                            .foregroundStyle(VaultTheme.textSecondary)
                    }
                } else {
                    List {
                        ForEach(log.entries) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(color(for: entry.event))
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.event.rawValue)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(VaultTheme.textPrimary)
                                    Text(dateFormatter.string(from: entry.timestamp))
                                        .font(.caption)
                                        .foregroundStyle(VaultTheme.textSecondary)
                                    if let detail = entry.detail, !detail.isEmpty {
                                        Text(detail)
                                            .font(.caption2)
                                            .foregroundStyle(VaultTheme.textSecondary.opacity(0.8))
                                    }
                                }
                            }
                            .listRowBackground(VaultTheme.surface)
                            .listRowSeparatorTint(VaultTheme.border)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Access Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(VaultTheme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(VaultTheme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func color(for event: AccessEventType) -> Color {
        switch event {
        case .unlockSuccess:
            return VaultTheme.success
        case .unlockFailed:
            return VaultTheme.danger
        case .lock, .autoLock, .backgroundLock:
            return VaultTheme.accentMuted
        case .emergencyLock:
            return VaultTheme.danger
        }
    }
}
