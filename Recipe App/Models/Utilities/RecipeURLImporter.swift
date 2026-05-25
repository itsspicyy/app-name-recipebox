import Foundation

class RecipeURLImporter {
    
    struct ImportResult {
        var title: String = ""
        var description: String = ""
        var ingredients: [String] = []
        var instructions: [String] = []
        var prepTime: Int = 0
        var cookTime: Int = 0
        var servings: Int = 4
        var imageURL: String? = nil
    }
    
    /// Fetch and parse a recipe from a URL
    static func importRecipe(from urlString: String) async -> ImportResult? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            
            // Try JSON-LD first (most recipe sites use this)
            if let result = parseJSONLD(html) { return result }
            
            // Fallback: basic HTML parsing
            return parseHTML(html)
        } catch {
            print("URL import failed: \(error)")
            return nil
        }
    }
    
    /// Convert ImportResult to a Recipe
    static func toRecipe(_ result: ImportResult) -> Recipe {
        var recipe = Recipe.blank()
        recipe.title = result.title
        recipe.description = result.description
        recipe.prepTimeMinutes = result.prepTime
        recipe.cookTimeMinutes = result.cookTime
        recipe.servings = result.servings > 0 ? result.servings : 4
        
        // Parse ingredient strings
        recipe.ingredients = result.ingredients.compactMap { line in
            let cleaned = line.trimmingCharacters(in: .whitespaces)
            guard !cleaned.isEmpty else { return nil }
            return Ingredient(quantity: "", unit: "", name: cleaned)
        }
        
        // Parse instruction strings into cooking steps
        recipe.cookingSteps = result.instructions.enumerated().compactMap { _, text in
            let cleaned = text.trimmingCharacters(in: .whitespaces)
            guard !cleaned.isEmpty else { return nil }
            return PrepStep(text: cleaned, timerSeconds: nil)
        }
        
        return recipe
    }
    
    // MARK: - JSON-LD Parser
    
    private static func parseJSONLD(_ html: String) -> ImportResult? {
        // Find JSON-LD script blocks
        let pattern = #"<script[^>]*type\s*=\s*"application/ld\+json"[^>]*>([\s\S]*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)
        
        for match in matches {
            guard let jsonRange = Range(match.range(at: 1), in: html) else { continue }
            let jsonString = String(html[jsonRange])
            
            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) else { continue }
            
            // Could be a single object or an array
            if let dict = json as? [String: Any] {
                if let result = extractRecipeFromJSON(dict) { return result }
            } else if let array = json as? [[String: Any]] {
                for dict in array {
                    if let result = extractRecipeFromJSON(dict) { return result }
                }
            }
        }
        
        return nil
    }
    
    private static func extractRecipeFromJSON(_ json: [String: Any]) -> ImportResult? {
        // Check @type is Recipe
        let typeValue = json["@type"]
        let isRecipe: Bool
        if let type = typeValue as? String {
            isRecipe = type == "Recipe"
        } else if let types = typeValue as? [String] {
            isRecipe = types.contains("Recipe")
        } else {
            // Check @graph for nested recipes
            if let graph = json["@graph"] as? [[String: Any]] {
                for item in graph {
                    if let result = extractRecipeFromJSON(item) { return result }
                }
            }
            return nil
        }
        
        guard isRecipe else { return nil }
        
        var result = ImportResult()
        
        result.title = json["name"] as? String ?? ""
        result.description = json["description"] as? String ?? ""
        
        // Ingredients
        if let ingredients = json["recipeIngredient"] as? [String] {
            result.ingredients = ingredients
        }
        
        // Instructions
        if let instructions = json["recipeInstructions"] as? [String] {
            result.instructions = instructions
        } else if let instructionObjects = json["recipeInstructions"] as? [[String: Any]] {
            result.instructions = instructionObjects.compactMap { $0["text"] as? String }
        }
        
        // Times (ISO 8601 duration format: PT30M, PT1H30M)
        if let prep = json["prepTime"] as? String {
            result.prepTime = parseISODuration(prep)
        }
        if let cook = json["cookTime"] as? String {
            result.cookTime = parseISODuration(cook)
        }
        
        // Servings
        if let yield = json["recipeYield"] as? String {
            let nums = yield.components(separatedBy: .decimalDigits.inverted).compactMap { Int($0) }
            result.servings = nums.first ?? 4
        } else if let yield = json["recipeYield"] as? [String], let first = yield.first {
            let nums = first.components(separatedBy: .decimalDigits.inverted).compactMap { Int($0) }
            result.servings = nums.first ?? 4
        }
        
        // Image
        if let image = json["image"] as? String {
            result.imageURL = image
        } else if let images = json["image"] as? [String] {
            result.imageURL = images.first
        } else if let imageObj = json["image"] as? [String: Any] {
            result.imageURL = imageObj["url"] as? String
        }
        
        return result
    }
    
    /// Parse ISO 8601 duration (PT30M, PT1H30M, PT2H) to minutes
    private static func parseISODuration(_ duration: String) -> Int {
        var minutes = 0
        let upper = duration.uppercased()
        
        // Hours
        if let hRange = upper.range(of: #"(\d+)H"#, options: .regularExpression) {
            let numStr = upper[hRange].dropLast()
            minutes += (Int(numStr) ?? 0) * 60
        }
        // Minutes
        if let mRange = upper.range(of: #"(\d+)M"#, options: .regularExpression) {
            let numStr = upper[mRange].dropLast()
            minutes += Int(numStr) ?? 0
        }
        
        return minutes
    }
    
    // MARK: - Basic HTML Fallback
    
    private static func parseHTML(_ html: String) -> ImportResult? {
        var result = ImportResult()
        
        // Try to get title from <title> or <h1>
        if let titleRange = html.range(of: #"<title[^>]*>(.*?)</title>"#, options: .regularExpression) {
            result.title = stripHTML(String(html[titleRange]))
        }
        
        // Very basic — just return the title so user can fill in the rest manually
        guard !result.title.isEmpty else { return nil }
        
        return result
    }
    
    private static func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
