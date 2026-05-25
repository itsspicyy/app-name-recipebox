import SwiftUI

struct TextImportView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss
    @State private var rawText = ""
    @State private var showEditor = false
    @State private var prefilledRecipe: Recipe? = nil
    
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
                    
                    Button {
                        let parsed = RecipeTextParser.parse(rawText)
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
                        showEditor = true
                    } label: {
                        HStack {
                            Image(systemName: "text.viewfinder")
                            Text("Parse & Import")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "2A9D8F"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Paste Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
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
}
