import SwiftUI
import PDFKit

struct FileDetailView: View {
    @ObservedObject var store: VaultStore
    let item: VaultItem

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var pdfData: Data?
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.background.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(VaultTheme.accent)
                } else if let image {
                    ScrollView {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding()
                    }
                } else if let pdfData {
                    PDFKitView(data: pdfData)
                        .ignoresSafeArea(edges: .bottom)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(VaultTheme.danger)
                        .padding()
                }
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(VaultTheme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(VaultTheme.accent)
                }
            }
            .task { await load() }
        }
        .preferredColorScheme(.dark)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try store.loadFileData(item)
            switch item.type {
            case .photo:
                image = UIImage(data: data)
                if image == nil { errorMessage = "Could not decode image." }
            case .pdf:
                pdfData = data
            case .note:
                errorMessage = "Unexpected item type."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.backgroundColor = UIColor(VaultTheme.background)
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.dataRepresentation() != data {
            uiView.document = PDFDocument(data: data)
        }
    }
}
