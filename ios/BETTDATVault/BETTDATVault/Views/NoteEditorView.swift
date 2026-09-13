import SwiftUI

enum NoteEditorMode {
    case create
    case edit(VaultItem)
}

struct NoteEditorView: View {
    @ObservedObject var store: VaultStore
    let mode: NoteEditorMode

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var errorMessage: String?
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    TextField("Title", text: $title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(VaultTheme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    Divider().overlay(VaultTheme.border)

                    TextEditor(text: $bodyText)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(VaultTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(VaultTheme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(VaultTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(VaultTheme.accent)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                guard !didLoad else { return }
                didLoad = true
                if case .edit(let item) = mode {
                    title = item.title
                    do {
                        bodyText = try store.loadNoteBody(item)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var navTitle: String {
        switch mode {
        case .create: return "New Note"
        case .edit: return "Edit Note"
        }
    }

    private func save() {
        do {
            switch mode {
            case .create:
                _ = try store.addNote(title: title, body: bodyText)
            case .edit(let item):
                try store.updateNote(item, title: title, body: bodyText)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
