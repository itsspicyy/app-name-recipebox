import SwiftUI
import PhotosUI
import AVFoundation

struct ImageImportView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var extractedText: String = ""
    @State private var parsedRecipe: ParsedRecipe? = nil
    @State private var currentPhase: ImportPhase = .pick
    @State private var showRecipeEditor = false
    @State private var prefilledRecipe: Recipe? = nil
    @State private var processingError: ProcessingError? = nil
    @State private var loadFailureCount = 0

    enum ImportPhase { case pick, processing, review }

    enum ProcessingError {
        case allPhotosFailed        // Every selected item failed to load
        case noTextFound            // Photos loaded but OCR returned nothing
        case sparseText             // Very short/garbage OCR result

        var title: String {
            switch self {
            case .allPhotosFailed: return "Couldn't Load Photos"
            case .noTextFound:     return "No Text Found"
            case .sparseText:      return "Very Little Text Detected"
            }
        }

        var message: String {
            switch self {
            case .allPhotosFailed:
                return "The selected photos couldn't be loaded. Try choosing different images, or paste the recipe text manually."
            case .noTextFound:
                return "No readable text was found in your selection. Try a clearer, well-lit photo where the text is easy to read."
            case .sparseText:
                return "Only a small amount of text was detected — the result may be incomplete. You can still review what was found and fill in the rest manually."
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F6F0").ignoresSafeArea()
                switch currentPhase {
                case .pick:       pickPhase
                case .processing: processingPhase
                case .review:     reviewPhase
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showRecipeEditor) {
                if let recipe = prefilledRecipe {
                    AddRecipeView(existingRecipe: recipe)
                }
            }
        }
    }

    private var navigationTitle: String {
        switch currentPhase {
        case .pick:       return "Import Recipe"
        case .processing: return "Scanning..."
        case .review:     return "Review Scan"
        }
    }

    // MARK: - Pick Phase

    private var pickPhase: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(Color(hex: "2A9D8F").opacity(0.5))
                .accessibilityHidden(true)

            Text("Import from Photos")
                .font(.title2.weight(.bold))

            Text("Select photos or a screen recording of a recipe. The app will scan the text and auto-fill your recipe.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Show a persistent error banner if a previous attempt failed
            if let error = processingError {
                FeedbackBanner(
                    icon: "xmark.circle.fill",
                    iconColor: .red,
                    backgroundColor: Color.red.opacity(0.07),
                    title: error.title,
                    message: error.message
                )
                .padding(.horizontal)
            }

            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 10,
                matching: .any(of: [.images, .videos])
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text(processingError != nil ? "Try Different Photos" : "Choose from Camera Roll")
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color(hex: "2A9D8F"))
                .clipShape(Capsule())
            }
            .accessibilityLabel("Choose photos to scan")
            .onChange(of: selectedItems) { _, items in
                guard !items.isEmpty else { return }
                processingError = nil
                loadFailureCount = 0
                currentPhase = .processing
                processSelectedItems(items)
            }

            Spacer()
        }
    }

    // MARK: - Processing Phase

    private var processingPhase: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "2A9D8F"))
            Text("Scanning your recipe...")
                .font(.title3.weight(.semibold))
            Text("Extracting text from \(selectedItems.count) item\(selectedItems.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scanning \(selectedItems.count) photo\(selectedItems.count == 1 ? "" : "s"), please wait")
    }

    // MARK: - Review Phase

    private var reviewPhase: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Quality warning banner (sparse text)
                    if case .sparseText = processingError {
                        FeedbackBanner(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: Color(hex: "E9C46A"),
                            backgroundColor: Color(hex: "E9C46A").opacity(0.12),
                            title: "Partial result",
                            message: "Not much text was detected. Review what was found and add anything missing in the editor."
                        )
                    }

                    // Auto-detected summary card
                    if let parsed = parsedRecipe {
                        summaryCard(parsed)
                    }

                    // Raw text
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Extracted Text")
                                .font(.headline)
                            Spacer()
                            Text("\(extractedText.components(separatedBy: "\n").filter { !$0.isEmpty }.count) lines")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if extractedText.isEmpty {
                            Text("No text was detected.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Text(extractedText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    // Partial-load warning
                    if loadFailureCount > 0 {
                        FeedbackBanner(
                            icon: "exclamationmark.circle.fill",
                            iconColor: .orange,
                            backgroundColor: Color.orange.opacity(0.08),
                            title: "\(loadFailureCount) photo\(loadFailureCount == 1 ? "" : "s") couldn't be read",
                            message: "The rest were scanned successfully. If you're missing content, try rescanning with different photos."
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }

            // Bottom action bar
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    Button {
                        currentPhase = .pick
                        selectedItems = []
                        extractedText = ""
                        parsedRecipe = nil
                        processingError = nil
                        loadFailureCount = 0
                    } label: {
                        Text("Rescan")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color(hex: "264653"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "264653").opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        buildPrefilledRecipe()
                        showRecipeEditor = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(extractedText.isEmpty ? "Open Blank Editor" : "Use This")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "2A9D8F"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel(extractedText.isEmpty ? "Open blank recipe editor" : "Use scanned recipe")
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(hex: "F8F6F0"))
            }
        }
    }

    // MARK: - Summary Card

    private func summaryCard(_ parsed: ParsedRecipe) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").foregroundStyle(Color(hex: "F4A261"))
                Text("Auto-Detected")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: "F4A261"))
            }

            if !parsed.title.isEmpty {
                HStack(spacing: 6) {
                    Text("Title:").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(parsed.title).font(.subheadline.weight(.medium))
                }
            }

            HStack(spacing: 16) {
                detectedBadge("\(parsed.ingredients.count) ingredients", icon: "leaf.fill")
                detectedBadge("\(parsed.preparationSteps.count) prep steps", icon: "hands.sparkles.fill")
                detectedBadge("\(parsed.cookingSteps.count) cook steps", icon: "flame.fill")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "FFF8E7"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func detectedBadge(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(Color(hex: "264653"))
    }

    // MARK: - Processing Logic

    private func processSelectedItems(_ items: [PhotosPickerItem]) {
        var allTexts: [String] = []
        var failureCount = 0
        let group = DispatchGroup()

        for item in items {
            group.enter()
            if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) || $0.conforms(to: .video) }) {
                item.loadTransferable(type: VideoTransferable.self) { result in
                    switch result {
                    case .success(let video?):
                        TextRecognizer.recognizeText(fromVideoAt: video.url) { text in
                            if !text.isEmpty { allTexts.append(text) }
                            else { failureCount += 1 }
                            group.leave()
                        }
                    default:
                        failureCount += 1
                        group.leave()
                    }
                }
            } else {
                item.loadTransferable(type: Data.self) { result in
                    switch result {
                    case .success(let data?):
                        if let image = UIImage(data: data) {
                            TextRecognizer.recognizeText(from: image) { text in
                                if !text.isEmpty { allTexts.append(text) }
                                else { failureCount += 1 }
                                group.leave()
                            }
                        } else {
                            failureCount += 1
                            group.leave()
                        }
                    default:
                        failureCount += 1
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) {
            self.loadFailureCount = failureCount

            // Every single item failed to load
            if allTexts.isEmpty && failureCount == items.count {
                self.processingError = .allPhotosFailed
                self.currentPhase = .pick
                self.selectedItems = []
                return
            }

            let combined = allTexts.joined(separator: "\n\n")

            // OCR ran but returned nothing
            if combined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.processingError = .noTextFound
                self.currentPhase = .pick
                self.selectedItems = []
                return
            }

            // OCR returned very little — flag but still show review
            let wordCount = combined.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
            if wordCount < 15 {
                self.processingError = .sparseText
            }

            self.extractedText = combined
            self.parsedRecipe = RecipeTextParser.parse(combined)
            self.currentPhase = .review
        }
    }

    private func buildPrefilledRecipe() {
        guard let parsed = parsedRecipe else {
            prefilledRecipe = Recipe.blank()
            return
        }
        var recipe = Recipe.blank()
        recipe.title = parsed.title
        recipe.description = parsed.description
        recipe.ingredients = parsed.ingredients
        recipe.preparationSteps = parsed.preparationSteps
        recipe.cookingSteps = parsed.cookingSteps
        recipe.servings = parsed.servings
        recipe.prepTimeMinutes = parsed.prepTimeMinutes
        recipe.cookTimeMinutes = parsed.cookTimeMinutes
        prefilledRecipe = recipe
    }
}

// MARK: - Video Transferable

struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("recipe_video_\(UUID().uuidString).mov")
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: received.file, to: dest)
            return VideoTransferable(url: dest)
        }
    }
}
