import SwiftUI

struct TextImportView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss
    @State private var rawText = ""
    @State private var showEditor = false
    @State private var prefilledRecipe: Recipe? = nil
    @State private var parseWarning: ParseWarning? = nil

    enum ParseWarning {
        case noIngredients
        case noSteps
        case nothingDetected

        var title: String {
            switch self {
            case .noIngredients:   return "No Ingredients Detected"
            case .noSteps:         return "No Steps Detected"
            case .nothingDetected: return "Nothing Detected"
            }
        }

        var message: String {
            switch self {
            case .noIngredients:
                return "Steps were found but no ingredients were detected. You can add them manually in the editor."
            case .noSteps:
                return "Ingredients were found but no cooking steps were detected. You can add them manually in the editor."
            case .nothingDetected:
                return "Neither ingredients nor steps could be detected from this text. The editor will open blank — you can paste text into individual fields from there."
            }
        }
    }

    private var canParse: Bool {
        !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F6F0").ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Paste a recipe from anywhere — a website, a message, your notes — and we'll parse it automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    TextEditor(text: $rawText)
                        .font(.body)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                        .padding(.horizontal)
                        .frame(minHeight: 180)
                        .accessibilityLabel("Recipe text")
                        .accessibilityHint("Paste the full recipe text here")
                        .onChange(of: rawText) { _, _ in
                            // Clear warnings as user edits
                            parseWarning = nil
                        }

                    // Parse warning banner
                    if let warning = parseWarning {
                        FeedbackBanner(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: Color(hex: "E9C46A"),
                            backgroundColor: Color(hex: "E9C46A").opacity(0.12),
                            title: warning.title,
                            message: warning.message,
                            actionLabel: "Open Editor Anyway",
                            action: { showEditor = true }
                        )
                        .padding(.horizontal)
                    }

                    Button {
                        parseAndOpen()
                    } label: {
                        HStack {
                            Image(systemName: "text.viewfinder")
                            Text("Parse & Import")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canParse ? Color(hex: "2A9D8F") : Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canParse)
                    .padding(.horizontal)
                    .accessibilityLabel("Parse and import recipe")
                    .accessibilityHint(canParse ? "" : "Paste some recipe text first")
                }
                .padding(.top, 16)
            }
            .navigationTitle("Paste Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showEditor) {
                if let recipe = prefilledRecipe {
                    AddRecipeView(existingRecipe: recipe)
                }
            }
        }
    }

    // MARK: - Parse Logic

    private func parseAndOpen() {
        let parsed = RecipeTextParser.parse(rawText)

        // Build a prefilled recipe regardless — even a blank one is useful
        var recipe = Recipe.blank()
        recipe.title           = parsed.title
        recipe.description     = parsed.description
        recipe.ingredients     = parsed.ingredients
        recipe.preparationSteps = parsed.preparationSteps
        recipe.cookingSteps    = parsed.cookingSteps
        recipe.servings        = parsed.servings
        recipe.prepTimeMinutes = parsed.prepTimeMinutes
        recipe.cookTimeMinutes = parsed.cookTimeMinutes
        prefilledRecipe = recipe

        let hasIngredients = !parsed.ingredients.isEmpty
        let hasSteps = !parsed.cookingSteps.isEmpty && !parsed.preparationSteps.isEmpty

        if hasIngredients && (hasSteps || !parsed.cookingSteps.isEmpty || !parsed.preparationSteps.isEmpty) {
            // Good result — open editor directly
            parseWarning = nil
            showEditor = true
        } else if hasIngredients && !hasSteps {
            parseWarning = .noSteps
        } else if !hasIngredients && (hasSteps || !parsed.cookingSteps.isEmpty) {
            parseWarning = .noIngredients
        } else {
            parseWarning = .nothingDetected
        }
    }
}
