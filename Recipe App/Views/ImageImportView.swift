import SwiftUI
import PhotosUI
import AVFoundation

struct ImageImportView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var extractedText: String = ""
    @State private var parsedRecipe: ParsedRecipe? = nil
    @State private var isProcessing = false
    @State private var currentPhase: ImportPhase = .pick
    @State private var showRecipeEditor = false
    @State private var prefilledRecipe: Recipe? = nil
    
    enum ImportPhase {
        case pick
        case processing
        case review
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F6F0").ignoresSafeArea()
                
                switch currentPhase {
                case .pick:
                    pickPhase
                case .processing:
                    processingPhase
                case .review:
                    reviewPhase
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
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
        case .pick: return "Import Recipe"
        case .processing: return "Scanning..."
        case .review: return "Scanned Text"
        }
    }
    
    // MARK: - Pick Phase
    
    private var pickPhase: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(Color(hex: "2A9D8F").opacity(0.5))
            
            Text("Import from Photos")
                .font(.title2.weight(.bold))
            
            Text("Select photos or a screen recording of a recipe. The app will scan the text and auto-fill your recipe.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 10,
                matching: .any(of: [.images, .videos])
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Choose from Camera Roll")
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color(hex: "2A9D8F"))
                .clipShape(Capsule())
            }
            .onChange(of: selectedItems) { items in
                guard !items.isEmpty else { return }
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
    }
    
    // MARK: - Review Phase
    
    private var reviewPhase: some View {
        VStack(spacing: 0) {
            if extractedText.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No text found")
                        .font(.title3.weight(.semibold))
                    Text("Try a clearer image or a different photo of the recipe.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button {
                        currentPhase = .pick
                        selectedItems = []
                        extractedText = ""
                    } label: {
                        Text("Try Again")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color(hex: "2A9D8F"))
                    }
                    .padding(.top, 8)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Summary card
                        if let parsed = parsedRecipe {
                            summaryCard(parsed)
                        }
                        
                        // Raw text preview
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Extracted Text")
                                    .font(.headline)
                                Spacer()
                                Text("\(extractedText.components(separatedBy: "\n").count) lines")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(extractedText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
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
                                Text("Use This")
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "2A9D8F"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(hex: "F8F6F0"))
                }
            }
        }
    }
    
    private func summaryCard(_ parsed: ParsedRecipe) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color(hex: "F4A261"))
                Text("Auto-Detected")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: "F4A261"))
            }
            
            if !parsed.title.isEmpty {
                HStack(spacing: 6) {
                    Text("Title:")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(parsed.title)
                        .font(.subheadline.weight(.medium))
                }
            }
            
            HStack(spacing: 16) {
                detectedBadge("\(parsed.ingredients.count) ingredients", icon: "leaf.fill")
                detectedBadge("\(parsed.preparationSteps.count) prep steps", icon: "hands.sparkles.fill")
                detectedBadge("\(parsed.cookingSteps.count) cook steps", icon: "flame.fill")
            }
            
            if parsed.servings != 4 || parsed.prepTimeMinutes > 0 || parsed.cookTimeMinutes > 0 {
                HStack(spacing: 12) {
                    if parsed.servings != 4 {
                        detectedBadge("\(parsed.servings) servings", icon: "person.2.fill")
                    }
                    if parsed.prepTimeMinutes > 0 {
                        detectedBadge("\(parsed.prepTimeMinutes)m prep", icon: "clock.fill")
                    }
                    if parsed.cookTimeMinutes > 0 {
                        detectedBadge("\(parsed.cookTimeMinutes)m cook", icon: "timer")
                    }
                }
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
        let group = DispatchGroup()
        
        for item in items {
            group.enter()
            
            // Check if it's a video
            if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) || $0.conforms(to: .video) }) {
                // Load video as file URL
                item.loadTransferable(type: VideoTransferable.self) { result in
                    switch result {
                    case .success(let video):
                        if let video = video {
                            TextRecognizer.recognizeText(fromVideoAt: video.url) { text in
                                if !text.isEmpty { allTexts.append(text) }
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    case .failure:
                        group.leave()
                    }
                }
            } else {
                // Load as image
                item.loadTransferable(type: Data.self) { result in
                    switch result {
                    case .success(let data):
                        if let data = data, let image = UIImage(data: data) {
                            TextRecognizer.recognizeText(from: image) { text in
                                if !text.isEmpty { allTexts.append(text) }
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    case .failure:
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            extractedText = allTexts.joined(separator: "\n\n")
            parsedRecipe = RecipeTextParser.parse(extractedText)
            currentPhase = .review
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
            // Copy to a temp location
            let tempDir = FileManager.default.temporaryDirectory
            let filename = "recipe_video_\(UUID().uuidString).mov"
            let destination = tempDir.appendingPathComponent(filename)
            
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: received.file, to: destination)
            
            return VideoTransferable(url: destination)
        }
    }
}
