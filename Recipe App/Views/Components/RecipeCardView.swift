import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    
    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let d = recipe.imageData, let img = UIImage(data: d) { Image(uiImage: img).resizable().scaledToFill() }
                else { ZStack { LinearGradient(colors: [recipe.category.color.opacity(0.25), recipe.category.color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing); Image(systemName: recipe.category.icon).font(.title3).foregroundStyle(recipe.category.color.opacity(0.5)) } }
            }.frame(width: 80, height: 80).clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title).font(.headline).foregroundStyle(.primary).lineLimit(2)
                if !recipe.description.isEmpty { Text(recipe.description).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                HStack(spacing: 10) {
                    Label(recipe.category.rawValue, systemImage: recipe.category.icon).font(.caption2).foregroundStyle(recipe.category.color)
                    Label(recipe.totalTimeDisplay, systemImage: "clock").font(.caption2).foregroundStyle(.secondary)
                    Label(recipe.difficulty.rawValue, systemImage: "chart.bar.fill").font(.caption2).foregroundStyle(recipe.difficulty.color)
                }
                HStack(spacing: 10) {
                    if let avg = recipe.averageRating { StarRatingDisplay(rating: avg, size: 10) }
                    if recipe.timesCookedTotal > 0 { Label("\(recipe.timesCookedTotal)x", systemImage: "fork.knife").font(.caption2).foregroundStyle(.secondary) }
                    Spacer()
                    if recipe.isFavorite { Image(systemName: "heart.fill").font(.caption).foregroundStyle(.red) }
                }
            }
        }
        .padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14)).shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        .contextMenu {
            Button { store.toggleFavorite(recipe) } label: { Label(recipe.isFavorite ? "Unfavorite" : "Favorite", systemImage: recipe.isFavorite ? "heart.slash" : "heart") }
            Button { store.logCookingSession(for: recipe) } label: { Label("Log as Cooked", systemImage: "checkmark.circle") }
            Button(role: .destructive) { store.deleteRecipe(recipe) } label: { Label("Delete", systemImage: "trash") }
        }
    }
}
