import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct VaultHomeView: View {
    @ObservedObject var store: VaultStore
    @ObservedObject var auth: AuthenticationService
    @State private var showingNewNote = false
    @State private var showingSettings = false
    @State private var showingLog = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showingFileImporter = false
    @State private var errorMessage: String?
    @State private var selectedItem: VaultItem?

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.background.ignoresSafeArea()

                if store.items.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.items) { item in
                            Button {
                                selectedItem = item
                            } label: {
                                itemRow(item)
                            }
                            .listRowBackground(VaultTheme.surface)
                            .listRowSeparatorTint(VaultTheme.border)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    try? store.delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Vault")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(VaultTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showingNewNote = true
                        } label: {
                            Label("New Note", systemImage: "note.text")
                        }
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            Label("Import Photo", systemImage: "photo")
                        }
                        Button {
                            showingFileImporter = true
                        } label: {
                            Label("Import PDF", systemImage: "doc.richtext")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(VaultTheme.accent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingLog = true
                        } label: {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .foregroundStyle(VaultTheme.textSecondary)
                        }
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(VaultTheme.textSecondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewNote) {
                NoteEditorView(store: store, mode: .create)
            }
            .sheet(item: $selectedItem) { item in
                Group {
                    if item.type == .note {
                        NoteEditorView(store: store, mode: .edit(item))
                    } else {
                        FileDetailView(store: store, item: item)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(auth: auth)
            }
            .sheet(isPresented: $showingLog) {
                AccessLogView(log: AccessLogService.shared)
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handlePDFImport(result)
            }
            .onChange(of: photoPickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await importPhoto(newItem) }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(VaultTheme.accentMuted)
            Text("Vault is empty")
                .font(.headline)
                .foregroundStyle(VaultTheme.textPrimary)
            Text("Add a note, photo, or PDF.\nEverything stays encrypted on this device.")
                .font(.subheadline)
                .foregroundStyle(VaultTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func itemRow(_ item: VaultItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: iconName(for: item.type))
                .font(.title3)
                .foregroundStyle(VaultTheme.accent)
                .frame(width: 36, height: 36)
                .background(VaultTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(VaultTheme.textPrimary)
                    .lineLimit(1)
                Text(item.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(VaultTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(VaultTheme.textSecondary.opacity(0.5))
        }
        .padding(.vertical, 4)
    }

    private func iconName(for type: VaultItemType) -> String {
        switch type {
        case .note: return "note.text"
        case .photo: return "photo"
        case .pdf: return "doc.richtext"
        }
    }

    private func importPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "Could not load photo data."
                return
            }
            _ = try store.importFile(
                title: "Photo",
                data: data,
                type: .photo,
                originalFileName: "photo.jpg",
                contentType: "public.jpeg"
            )
            photoPickerItem = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handlePDFImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                _ = try store.importFile(
                    title: url.deletingPathExtension().lastPathComponent,
                    data: data,
                    type: .pdf,
                    originalFileName: url.lastPathComponent,
                    contentType: UTType.pdf.identifier
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
