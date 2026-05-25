import Foundation
import UIKit

struct RecipeLinkHelper {
    
    /// URL scheme for the app
    static let scheme = "recipebox"
    
    // MARK: - Encode recipe into a shareable URL
    
    /// Creates a recipebox:// deep link containing the full recipe as compressed base64 JSON
    static func createLink(for recipe: Recipe) -> URL? {
        do {
            let data = try JSONEncoder().encode(recipe)
            let compressed = try (data as NSData).compressed(using: .lzfse) as Data
            let base64 = compressed.base64EncodedString()
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            var components = URLComponents()
            components.scheme = scheme
            components.host = "import"
            components.queryItems = [URLQueryItem(name: "recipe", value: base64)]
            
            return components.url
        } catch {
            print("Failed to encode recipe link: \(error)")
            return nil
        }
    }
    
    // MARK: - Decode recipe from an incoming URL
    
    /// Parses a recipebox://import?recipe=... URL back into a Recipe
    static func decodeRecipe(from url: URL) -> Recipe? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == scheme,
              components.host == "import",
              let base64 = components.queryItems?.first(where: { $0.name == "recipe" })?.value,
              let compressed = Data(base64Encoded: base64) else {
            return nil
        }
        
        do {
            let decompressed = try (compressed as NSData).decompressed(using: .lzfse) as Data
            var recipe = try JSONDecoder().decode(Recipe.self, from: decompressed)
            // Give it a new ID so it doesn't clash with the sender's copy
            recipe.id = UUID()
            recipe.dateCreated = Date()
            recipe.dateModified = Date()
            recipe.isFavorite = false
            recipe.collections = []
            return recipe
        } catch {
            print("Failed to decode recipe from link: \(error)")
            return nil
        }
    }
    
    // MARK: - Share recipe (link + text fallback)
    
    /// Presents the share sheet with both a deep link and formatted text fallback
    static func share(_ recipe: Recipe) {
        var shareItems: [Any] = []
        
        // Formatted text (always included as fallback)
        let text = formatAsText(recipe)
        shareItems.append(text)
        
        // Deep link (included so recipients with the app can tap to import)
        if let link = createLink(for: recipe) {
            shareItems.append(link)
        }
        
        let activityVC = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: nil
        )
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topVC.present(activityVC, animated: true)
    }
    
    // MARK: - Text Formatting
    
    /// Format a recipe as shareable plain text with the deep link at the top
    private static func formatAsText(_ recipe: Recipe) -> String {
        var text = ""
        
        // Deep link at top
        if let link = createLink(for: recipe) {
            text += "📲 Tap to add to Recipe Box:\n\(link.absoluteString)\n\n"
        }
        
        // Title
        text += "✦ \(recipe.title) ✦\n"
        text += String(repeating: "─", count: 30) + "\n\n"
        
        // Description
        if !recipe.description.isEmpty {
            text += "\(recipe.description)\n\n"
        }
        
        // Info line
        var info: [String] = []
        info.append("📂 \(recipe.category.rawValue)")
        info.append("⏱ \(recipe.totalTimeDisplay)")
        info.append("🍽 \(recipe.servings) servings")
        info.append("📊 \(recipe.difficulty.rawValue)")
        text += info.joined(separator: "  •  ") + "\n\n"
        
        // Sub-categories
        if !recipe.subCategories.isEmpty {
            let tags = recipe.subCategories.map { $0.rawValue }.joined(separator: ", ")
            text += "Tags: \(tags)\n\n"
        }
        
        // Ingredients
        if !recipe.ingredients.isEmpty {
            text += "── INGREDIENTS ──\n"
            for ing in recipe.ingredients {
                text += "  • \(ing.displayText)\n"
            }
            text += "\n"
        }
        
        // Preparation
        if !recipe.preparationSteps.isEmpty {
            text += "── PREPARATION ──\n"
            for (idx, step) in recipe.preparationSteps.enumerated() {
                text += "  \(idx + 1). \(step.text)\n"
            }
            text += "\n"
        }
        
        // Cooking Steps
        if !recipe.cookingSteps.isEmpty {
            text += "── COOKING STEPS ──\n"
            for (idx, step) in recipe.cookingSteps.enumerated() {
                var line = "  \(idx + 1). \(step.text)"
                if let timer = step.timerDisplay {
                    line += " ⏱ \(timer)"
                }
                text += line + "\n"
            }
            text += "\n"
        }
        
        // Notes
        if !recipe.notes.isEmpty {
            text += "── NOTES ──\n"
            text += "  \(recipe.notes)\n\n"
        }
        
        text += "Shared from Recipe Box 🍳"
        
        return text
    }
}
