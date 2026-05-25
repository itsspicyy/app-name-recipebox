import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !recipe.description.isEmpty {
                    Text(recipe.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 10) {
                    Label(recipe.category.rawValue, systemImage: recipe.category.icon)
                        .font(.caption2)
                        .foregroundStyle(recipe.category.color)
                    Label(recipe.totalTimeDisplay, systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Label(recipe.difficulty.rawValue, systemImage: "chart.bar.fill")
                        .font(.caption2)
                        .foregroundStyle(recipe.difficulty.color)
                }

                HStack(spacing: 10) {
                    if let avg = recipe.averageRating {
                        StarRatingDisplay(rating: avg, size: 10)
                    }
                    if recipe.timesCookedTotal > 0 {
                        Label("\(recipe.timesCookedTotal)×", systemImage: "fork.knife")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if recipe.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityHidden(true) // Conveyed in the combined label below
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        // Combine all children into one accessible element so VoiceOver
        // reads the card as a unit: title, description, category, time, difficulty.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(cardAccessibilityLabel)
        .contextMenu {
            Button {
                HapticManager.light()
                store.toggleFavorite(recipe)
            } label: {
                Label(
                    recipe.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: recipe.isFavorite ? "heart.slash" : "heart"
                )
            }

            Button {
                HapticManager.medium()
                store.logCookingSession(for: recipe)
            } label: {
                Label("Log as Cooked", systemImage: "checkmark.circle")
            }

            Button(role: .destructive) {
                HapticManager.heavy()
                store.deleteRecipe(recipe)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Accessibility Label

    /// Builds a natural-language summary of the card for VoiceOver.
    private var cardAccessibilityLabel: String {
        var parts: [String] = [recipe.title]
        if !recipe.description.isEmpty { parts.append(recipe.description) }
        parts.append("\(recipe.category.rawValue), \(recipe.totalTimeDisplay), \(recipe.difficulty.rawValue)")
        if let avg = recipe.averageRating {
            let formatted = avg == avg.rounded() ? String(Int(avg)) : String(format: "%.1f", avg)
            parts.append("Rated \(formatted) out of 5 stars")
        }
        if recipe.timesCookedTotal > 0 {
            parts.append("Cooked \(recipe.timesCookedTotal) time\(recipe.timesCookedTotal == 1 ? "" : "s")")
        }
        if recipe.isFavorite { parts.append("Favorited") }
        return parts.joined(separator: ". ")
    }

    // MARK: - Thumbnail

    private var thumbnail: some View {
        Group {
            if let d = recipe.imageData, let img = UIImage(data: d) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [recipe.category.color.opacity(0.25), recipe.category.color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: recipe.category.icon)
                        .font(.title3)
                        .foregroundStyle(recipe.category.color.opacity(0.5))
                }
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityHidden(true) // Decorative; info is in the combined label
    }
}

#Preview {
    RecipeCardView(recipe: Recipe(
        title: "Chicken Tikka Masala",
        category: .dinner,
        subCategories: [.comfortFood],
        description: "Creamy, spiced tomato sauce with tender chicken.",
        difficulty: .medium,
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
        servings: 4,
        ingredients: [],
        preparationSteps: [],
        cookingSteps: [],
        notes: "",
        isFavorite: true,
        collections: [],
        imageData: nil,
        dateCreated: Date(),
        dateModified: Date(),
        rating: nil,
        cookingLog: [],
        seasons: [.allYear],
        versions: [],
        activeVersionID: nil
    ))
    .environmentObject(RecipeStore())
    .padding()
    .background(Color(hex: "F8F6F0"))
}
