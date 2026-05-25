import SwiftUI

struct URLImportView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss
    @State private var urlText = ""
    @State private var isLoading = false
    @State private var importState: ImportState = .idle
    @State private var showEditor = false
    @State private var prefilledRecipe: Recipe? = nil
    @State private var importTask: Task<Void, Never>? = nil

    enum ImportState {
        case idle
        case error(ImportErrorKind)
        case sparseResult(String)
    }

    enum ImportErrorKind {
        case invalidURL
        case timeout
        case noRecipeFound
        case blocked

        var title: String {
            switch self {
            case .invalidURL:    return "Invalid URL"
            case .timeout:       return "Request Timed Out"
            case .noRecipeFound: return "No Recipe Found"
            case .blocked:       return "Website Blocked Access"
            }
        }

        var message: String {
            switch self {
            case .invalidURL:
                return "That doesn't look like a valid web address. Make sure it starts with https:// and points to a recipe page."
            case .timeout:
                return "The website took too long to respond. Try again, or paste the recipe text manually using \"Paste from Text\"."
            case .noRecipeFound:
                return "The page loaded but didn't contain a recognizable recipe. Try a different URL, or copy the text and use \"Paste from Text\"."
            case .blocked:
                return "This website doesn't allow automated access. Copy the recipe text and use \"Paste from Text\" instead."
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F6F0").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 12)

                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color(hex: "2A9D8F").opacity(0.5))
                            .accessibilityHidden(true)

                        Text("Import from URL")
                            .font(.title2.weight(.bold))

                        Text("Paste a link to a recipe page. Most recipe websites include structured data that the app can parse automatically.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        TextField("https://www.example.com/recipe/...", text: $urlText)
                            .textFieldStyle(.plain)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                            .padding(.horizontal)
                            .accessibilityLabel("Recipe URL")
                            .accessibilityHint("Paste the web address of a recipe page")
                            .onChange(of: urlText) { _, _ in
                                importState = .idle
                            }

                        stateMessage

                        Button {
                            importTask?.cancel()
                            importTask = Task { await runImport() }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                }
                                Text(isLoading ? "Importing..." : "Import Recipe")
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "2A9D8F"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        .padding(.horizontal)
                        .accessibilityLabel(isLoading ? "Importing recipe, please wait" : "Import recipe")

                        if isLoading {
                            Button("Cancel") {
                                importTask?.cancel()
                                importTask = nil
                                isLoading = false
                                importState = .idle
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Cancel import")
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Import from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        importTask?.cancel()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showEditor) {
                if let recipe = prefilledRecipe {
                    AddRecipeView(existingRecipe: recipe)
                }
            }
        }
    }

    // MARK: - State Feedback

    @ViewBuilder
    private var stateMessage: some View {
        switch importState {
        case .idle:
            EmptyView()

        case .error(let kind):
            FeedbackBanner(
                icon: "xmark.circle.fill",
                iconColor: .red,
                backgroundColor: Color.red.opacity(0.07),
                title: kind.title,
                message: kind.message
            )
            .padding(.horizontal)

        case .sparseResult(let detail):
            FeedbackBanner(
                icon: "exclamationmark.triangle.fill",
                iconColor: Color(hex: "E9C46A"),
                backgroundColor: Color(hex: "E9C46A").opacity(0.12),
                title: "Partial import",
                message: detail,
                actionLabel: "Open in Editor Anyway",
                action: { showEditor = true }
            )
            .padding(.horizontal)
        }
    }

    // MARK: - Import Logic

    @MainActor
    private func runImport() async {
        let raw = urlText.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Validate URL format before hitting the network
        guard isValidURL(raw) else {
            importState = .error(.invalidURL)
            return
        }

        // Single let — safe to capture in concurrent code
        let cleanURL = raw.hasPrefix("http") ? raw : "https://" + raw

        isLoading = true
        importState = .idle

        // 2. Run with a 20-second timeout
        let outcome = await withImportTimeout(seconds: 20) {
            await RecipeURLImporter.importRecipe(from: cleanURL)
        }

        isLoading = false
        guard !Task.isCancelled else { return }

        switch outcome {
        case .timedOut:
            importState = .error(.timeout)
            return

        case .completed(nil):
            if isLikelyBlockedSite(cleanURL) {
                importState = .error(.blocked)
            } else {
                importState = .error(.noRecipeFound)
            }
            return

        case .completed(let parsed?):
            let recipe = RecipeURLImporter.toRecipe(parsed)
            prefilledRecipe = recipe

            let hasIngredients = !parsed.ingredients.isEmpty
            let hasSteps       = !parsed.instructions.isEmpty
            let hasTitle       = !parsed.title.isEmpty

            if hasIngredients && hasSteps {
                importState = .idle
                showEditor  = true
            } else if hasIngredients && !hasSteps {
                importState = .sparseResult("Ingredients were found but no steps were detected. You can add them in the editor.")
            } else if !hasIngredients && hasSteps {
                importState = .sparseResult("Steps were found but no ingredients were detected. You can add them in the editor.")
            } else if hasTitle {
                importState = .sparseResult("Only a title was detected (\"\(parsed.title)\"). The site may not expose full recipe data — try pasting the text manually.")
            } else {
                importState = .error(.noRecipeFound)
            }
        }
    }

    // MARK: - Helpers

    private func isValidURL(_ string: String) -> Bool {
        let candidate = string.hasPrefix("http") ? string : "https://" + string
        guard let url = URL(string: candidate), let host = url.host, !host.isEmpty else { return false }
        return host.contains(".")
    }

    private func isLikelyBlockedSite(_ url: String) -> Bool {
        let known = ["nytimes.com", "epicurious.com", "bonappetit.com", "washingtonpost.com"]
        return known.contains(where: { url.contains($0) })
    }
}

// MARK: - Timeout Wrapper

private enum ImportOutcome<T> {
    case completed(T)
    case timedOut
}

private func withImportTimeout<T: Sendable>(
    seconds: Double,
    operation: @escaping @Sendable () async -> T
) async -> ImportOutcome<T> {
    await withTaskGroup(of: ImportOutcome<T>.self) { group in
        group.addTask { .completed(await operation()) }
        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return .timedOut
        }
        let first = await group.next()!
        group.cancelAll()
        return first
    }
}

// MARK: - Shared Feedback Banner

struct FeedbackBanner: View {
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.body)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let label = actionLabel, let action = action {
                    Button(label, action: action)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "2A9D8F"))
                        .padding(.top, 2)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
