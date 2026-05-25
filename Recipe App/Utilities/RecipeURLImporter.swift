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
        
        // Parse ingredient strings through RecipeTextParser for proper quantity/unit/name splitting
        recipe.ingredients = result.ingredients.compactMap { line in
            let cleaned = line.trimmingCharacters(in: .whitespaces)
            guard !cleaned.isEmpty else { return nil }
            return RecipeTextParser.parseIngredientLine(cleaned)
        }
        
        // Parse instruction strings into cooking steps
        recipe.cookingSteps = result.instructions.compactMap { text in
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
        
        // Instructions — handle all JSON-LD formats:
        // [String], [HowToStep], [HowToSection containing HowToStep], or mixed
        if let rawInstructions = json["recipeInstructions"] {
            result.instructions = extractInstructions(from: rawInstructions)
        }
        
        // Times (ISO 8601 duration format: PT30M, PT1H30M)
        if let prep = json["prepTime"] as? String {
            result.prepTime = parseISODuration(prep)
        }
        if let cook = json["cookTime"] as? String {
            result.cookTime = parseISODuration(cook)
        }
        
        // Servings — handle all the formats recipe sites use
        result.servings = parseYield(json["recipeYield"]) ?? 4
        
        // Image
        if let image = json["image"] as? String {
            result.imageURL = image
        } else if let images = json["image"] as? [String] {
            result.imageURL = images.first
        } else if let imageObj = json["image"] as? [String: Any] {
            result.imageURL = imageObj["url"] as? String
        } else if let imageArr = json["image"] as? [[String: Any]], let first = imageArr.first {
            result.imageURL = first["url"] as? String
        }
        
        return result
    }
    
    /// Recursively extract instruction text from any JSON-LD format
    private static func extractInstructions(from value: Any) -> [String] {
        var results: [String] = []
        
        // Plain string
        if let str = value as? String {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { results.append(trimmed) }
            return results
        }
        
        // Array of strings
        if let arr = value as? [String] {
            return arr.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        // Single object (HowToStep, HowToSection, etc.)
        if let dict = value as? [String: Any] {
            results.append(contentsOf: extractInstructionsFromObject(dict))
            return results
        }
        
        // Array of objects
        if let arr = value as? [[String: Any]] {
            for obj in arr {
                results.append(contentsOf: extractInstructionsFromObject(obj))
            }
            return results
        }
        
        // Mixed array (strings and objects)
        if let arr = value as? [Any] {
            for item in arr {
                results.append(contentsOf: extractInstructions(from: item))
            }
        }
        
        return results
    }
    
    /// Extract instruction text from a single JSON-LD object
    private static func extractInstructionsFromObject(_ obj: [String: Any]) -> [String] {
        var results: [String] = []
        let type = obj["@type"] as? String ?? ""
        
        switch type {
        case "HowToStep":
            // HowToStep has a "text" field
            if let text = obj["text"] as? String {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { results.append(trimmed) }
            }
            
        case "HowToSection":
            // HowToSection contains itemListElement with HowToStep items
            if let items = obj["itemListElement"] as? [[String: Any]] {
                for item in items {
                    results.append(contentsOf: extractInstructionsFromObject(item))
                }
            } else if let items = obj["itemListElement"] as? [Any] {
                for item in items {
                    results.append(contentsOf: extractInstructions(from: item))
                }
            }
            
        default:
            // Unknown type — try "text" field first, then itemListElement
            if let text = obj["text"] as? String {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { results.append(trimmed) }
            } else if let items = obj["itemListElement"] as? [Any] {
                for item in items {
                    results.append(contentsOf: extractInstructions(from: item))
                }
            }
        }
        
        return results
    }
    
    /// Parse recipeYield which can be: Int, String, [String], [Int], or nested object
    private static func parseYield(_ value: Any?) -> Int? {
        guard let value = value else { return nil }
        
        // Direct integer: recipeYield: 12
        if let intVal = value as? Int, intVal > 0 {
            return intVal
        }
        
        // Double that's really an int: recipeYield: 12.0
        if let doubleVal = value as? Double, doubleVal > 0 {
            return Int(doubleVal)
        }
        
        // Single string: "12", "12 servings", "1 loaf (12 slices)", "Makes 8"
        if let str = value as? String {
            return extractServingsFromString(str)
        }
        
        // Array of strings: ["12", "12 servings"]
        if let arr = value as? [String] {
            for str in arr {
                if let n = extractServingsFromString(str) { return n }
            }
        }
        
        // Array of ints
        if let arr = value as? [Int], let first = arr.first, first > 0 {
            return first
        }
        
        return nil
    }
    
    /// Extract a reasonable serving number from a yield string
    private static func extractServingsFromString(_ str: String) -> Int? {
        let lower = str.lowercased().trimmingCharacters(in: .whitespaces)
        
        // If it's just a number, use it
        if let n = Int(lower), n > 0, n <= 100 {
            return n
        }
        
        // Look for explicit serving counts: "12 servings", "8 portions", "24 slices"
        let servingPatterns = [
            #"(\d+)\s*(?:servings?|portions?)"#,
            #"(?:serves?|makes?|yields?)\s*:?\s*(\d+)"#
        ]
        
        for pattern in servingPatterns {
            if let match = lower.range(of: pattern, options: .regularExpression) {
                let matched = String(lower[match])
                let nums = matched.components(separatedBy: .decimalDigits.inverted)
                    .filter { !$0.isEmpty }
                    .compactMap { Int($0) }
                if let n = nums.first, n > 0, n <= 100 { return n }
            }
        }
        
        // Look for slice/piece counts: "12 slices", "24 pieces", "16 bars", "12 cookies", "24 muffins"
        let piecePatterns = [
            #"(\d+)\s*(?:slices?|pieces?|bars?|cookies?|muffins?|cupcakes?|brownies?|rolls?|biscuits?|scones?)"#
        ]
        
        for pattern in piecePatterns {
            if let match = lower.range(of: pattern, options: .regularExpression) {
                let matched = String(lower[match])
                let nums = matched.components(separatedBy: .decimalDigits.inverted)
                    .filter { !$0.isEmpty }
                    .compactMap { Int($0) }
                if let n = nums.first, n > 0, n <= 100 { return n }
            }
        }
        
        // Check for parenthetical serving info: "1 loaf (12 slices)", "2 pans (about 16 servings)"
        if let parenRange = lower.range(of: #"\(([^)]+)\)"#, options: .regularExpression) {
            let parenContent = String(lower[parenRange])
            // Recursively try to parse the content inside parentheses
            let inner = parenContent.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
            if let n = extractServingsFromString(inner) { return n }
        }
        
        // Whole-item yields: "1 loaf", "1 pan", "1 batch", "1 cake", "1 pie", "2 loaves"
        // These describe a whole item, not a serving count — use sensible defaults
        let wholeItemWords = ["loaf", "loaves", "pan", "pans", "batch", "batches",
                              "cake", "cakes", "pie", "pies", "tart", "tarts",
                              "casserole", "dish", "pot", "skillet", "sheet",
                              "recipe", "bundle", "round", "ring", "tube"]
        
        if wholeItemWords.contains(where: { lower.contains($0) }) {
            // Don't return the number (e.g. "1" from "1 loaf"), return nil so we fall back to default 4
            return nil
        }
        
        // Last resort: grab the first number if no whole-item word was found
        let allNums = lower.components(separatedBy: .decimalDigits.inverted)
            .filter { !$0.isEmpty }
            .compactMap { Int($0) }
        
        if let n = allNums.first, n > 0, n <= 100 {
            return n
        }
        
        return nil
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
