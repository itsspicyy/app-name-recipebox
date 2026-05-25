import Foundation

struct ParsedRecipe {
    var title: String = ""
    var description: String = ""
    var ingredients: [Ingredient] = []
    var preparationSteps: [PrepStep] = []
    var cookingSteps: [PrepStep] = []
    var servings: Int = 4
    var prepTimeMinutes: Int = 0
    var cookTimeMinutes: Int = 0
}

class RecipeTextParser {
    
    /// Common units for detecting ingredient lines
    private static let units = [
        "cup", "cups", "c",
        "tablespoon", "tablespoons", "tbsp", "tbs", "tb",
        "teaspoon", "teaspoons", "tsp", "ts",
        "ounce", "ounces", "oz",
        "pound", "pounds", "lb", "lbs",
        "gram", "grams", "g",
        "kilogram", "kilograms", "kg",
        "milliliter", "milliliters", "ml",
        "liter", "liters", "l",
        "quart", "quarts", "qt",
        "pint", "pints", "pt",
        "gallon", "gallons", "gal",
        "pinch", "dash", "handful",
        "slice", "slices",
        "piece", "pieces",
        "clove", "cloves",
        "can", "cans",
        "package", "packages", "pkg",
        "bunch", "bunches",
        "stick", "sticks",
        "head", "heads",
        "sprig", "sprigs"
    ]
    
    /// Section header patterns
    private static let ingredientHeaders = [
        "ingredients", "ingredient list", "what you need",
        "you will need", "you'll need", "shopping list", "what you'll need"
    ]
    
    private static let prepHeaders = [
        "preparation", "prep", "before you start", "to prepare",
        "mise en place", "get ready"
    ]
    
    private static let stepHeaders = [
        "instructions", "directions", "steps", "method",
        "how to make", "procedure", "cooking steps",
        "cooking instructions", "cooking directions", "cooking method"
    ]
    
    /// Parse raw OCR text into a structured ParsedRecipe
    static func parse(_ text: String) -> ParsedRecipe {
        var result = ParsedRecipe()
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else { return result }
        
        // Try to extract title (first non-section-header line)
        if let firstLine = lines.first, !isSectionHeader(firstLine) {
            result.title = firstLine
        }
        
        // Detect sections and categorize lines
        var currentSection: Section = .unknown
        var ingredientLines: [String] = []
        var prepLines: [String] = []
        var stepLines: [String] = []
        var descriptionLines: [String] = []
        
        for (index, line) in lines.enumerated() {
            // Skip the title line
            if index == 0 && line == result.title { continue }
            
            // Check if this line is a section header
            if isIngredientHeader(line) {
                currentSection = .ingredients
                continue
            } else if isPrepHeader(line) {
                currentSection = .preparation
                continue
            } else if isStepHeader(line) {
                currentSection = .steps
                continue
            }
            
            // If we haven't found a section header yet, try to auto-detect
            if currentSection == .unknown {
                if looksLikeIngredient(line) {
                    currentSection = .ingredients
                } else if looksLikeStep(line) {
                    currentSection = .steps
                } else {
                    descriptionLines.append(line)
                    continue
                }
            }
            
            switch currentSection {
            case .ingredients:
                if looksLikeStep(line) && !looksLikeIngredient(line) {
                    currentSection = .steps
                    stepLines.append(cleanStepText(line))
                } else {
                    ingredientLines.append(line)
                }
            case .preparation:
                prepLines.append(cleanStepText(line))
            case .steps:
                stepLines.append(cleanStepText(line))
            case .unknown:
                descriptionLines.append(line)
            }
        }
        
        // Build description from uncategorized lines before first section
        if !descriptionLines.isEmpty {
            result.description = descriptionLines.prefix(3).joined(separator: " ")
        }
        
        // Parse ingredients
        result.ingredients = ingredientLines.compactMap { parseIngredientLine($0) }
        
        // Parse steps
        result.preparationSteps = prepLines.map { PrepStep(text: $0, timerSeconds: extractTimer(from: $0)) }
        result.cookingSteps = stepLines.map { PrepStep(text: $0, timerSeconds: extractTimer(from: $0)) }
        
        // If no prep steps but we have cooking steps, that's fine
        // If no cooking steps but we have prep steps, move them to cooking
        if result.cookingSteps.isEmpty && !result.preparationSteps.isEmpty {
            result.cookingSteps = result.preparationSteps
            result.preparationSteps = []
        }
        
        // Try to extract servings from text
        result.servings = extractServings(from: text) ?? 4
        
        // Try to extract times
        let times = extractTimes(from: text)
        result.prepTimeMinutes = times.prep
        result.cookTimeMinutes = times.cook
        
        return result
    }
    
    // MARK: - Section Detection
    
    private enum Section {
        case unknown, ingredients, preparation, steps
    }
    
    private static func isSectionHeader(_ line: String) -> Bool {
        isIngredientHeader(line) || isPrepHeader(line) || isStepHeader(line)
    }
    
    private static func isIngredientHeader(_ line: String) -> Bool {
        let lower = line.lowercased().trimmingCharacters(in: .punctuationCharacters)
        return ingredientHeaders.contains(where: { lower.contains($0) })
    }
    
    private static func isPrepHeader(_ line: String) -> Bool {
        let lower = line.lowercased().trimmingCharacters(in: .punctuationCharacters)
        return prepHeaders.contains(where: { lower.contains($0) })
    }
    
    private static func isStepHeader(_ line: String) -> Bool {
        let lower = line.lowercased().trimmingCharacters(in: .punctuationCharacters)
        return stepHeaders.contains(where: { lower.contains($0) })
    }
    
    // MARK: - Line Classification
    
    private static func looksLikeIngredient(_ line: String) -> Bool {
        let lower = line.lowercased()
        
        // Starts with a number or fraction
        let startsWithNumber = line.first?.isNumber == true ||
            line.hasPrefix("½") || line.hasPrefix("¼") || line.hasPrefix("¾") ||
            line.hasPrefix("⅓") || line.hasPrefix("⅔") || line.hasPrefix("⅛")
        
        // Contains a known unit
        let containsUnit = units.contains(where: { unit in
            let pattern = "\\b\(unit)\\b"
            return lower.range(of: pattern, options: .regularExpression) != nil
        })
        
        // Ingredient lines are usually short (under ~80 chars)
        let isShort = line.count < 80
        
        return (startsWithNumber || containsUnit) && isShort
    }
    
    private static func looksLikeStep(_ line: String) -> Bool {
        let lower = line.lowercased()
        
        // Starts with a step number: "1.", "1)", "Step 1"
        let stepPattern = #"^(?:step\s*)?\d+[\.\)\:]"#
        let startsWithStepNumber = lower.range(of: stepPattern, options: .regularExpression) != nil
        
        // Contains cooking verbs
        let cookingVerbs = ["heat", "cook", "bake", "stir", "mix", "add", "combine",
                           "pour", "place", "set", "bring", "boil", "simmer", "sauté",
                           "saute", "fry", "grill", "roast", "chop", "dice", "slice",
                           "mince", "preheat", "whisk", "fold", "toss", "season",
                           "serve", "garnish", "let", "allow", "remove", "transfer",
                           "drain", "rinse", "spread", "layer", "cover", "reduce",
                           "blend", "puree", "marinate", "brush", "coat"]
        
        let containsVerb = cookingVerbs.contains(where: { lower.contains($0) })
        
        // Longer than typical ingredient lines
        let isLonger = line.count > 30
        
        return startsWithStepNumber || (containsVerb && isLonger)
    }
    
    // MARK: - Ingredient Parsing
    
    private static func parseIngredientLine(_ line: String) -> Ingredient? {
        let cleaned = line
            .replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "·", with: "")
            .replacingOccurrences(of: "—", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        guard !cleaned.isEmpty else { return nil }
        
        // Try pattern: quantity unit name
        // e.g. "2 cups all-purpose flour" or "1/2 tsp salt"
        let pattern = #"^([\d½¼¾⅓⅔⅛\s/\.]+)?\s*((?:"# + units.joined(separator: "|") + #")\.?)?\s+(.+)$"#
        
        if cleaned.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
            // Simple split approach: extract leading number, then unit, then rest
            let components = cleaned.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            var quantity = ""
            var unit = ""
            var nameStartIndex = 0
            
            // First token: check if it's a number/fraction
            if let first = components.first, isQuantity(first) {
                quantity = first
                nameStartIndex = 1
                
                // Check for compound fraction: "1 1/2"
                if components.count > 1 && isQuantity(components[1]) && components[1].contains("/") {
                    quantity += " " + components[1]
                    nameStartIndex = 2
                }
                
                // Check if next token is a unit
                if nameStartIndex < components.count {
                    let possibleUnit = components[nameStartIndex].lowercased()
                        .trimmingCharacters(in: .punctuationCharacters)
                    if units.contains(possibleUnit) {
                        unit = components[nameStartIndex]
                            .trimmingCharacters(in: .punctuationCharacters)
                        nameStartIndex += 1
                    }
                }
            }
            
            let name = components.dropFirst(nameStartIndex).joined(separator: " ")
            
            if !name.isEmpty {
                return Ingredient(quantity: quantity, unit: unit, name: name)
            }
        }
        
        // Fallback: just put the whole line as the ingredient name
        return Ingredient(quantity: "", unit: "", name: cleaned)
    }
    
    private static func isQuantity(_ str: String) -> Bool {
        let cleaned = str.trimmingCharacters(in: .whitespaces)
        // Matches: "2", "1.5", "1/2", "½", etc.
        let pattern = #"^[\d½¼¾⅓⅔⅛]+[/\.\d]*$"#
        return cleaned.range(of: pattern, options: .regularExpression) != nil
    }
    
    // MARK: - Step Cleaning
    
    private static func cleanStepText(_ line: String) -> String {
        var cleaned = line
        
        // Remove leading step numbers: "1.", "1)", "Step 1:", "Step 1."
        let stepPattern = #"^(?:step\s*)?\d+[\.\)\:\-]\s*"#
        if let range = cleaned.range(of: stepPattern, options: [.regularExpression, .caseInsensitive]) {
            cleaned = String(cleaned[range.upperBound...])
        }
        
        // Remove leading bullets
        cleaned = cleaned
            .replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "·", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        // Capitalize first letter
        if let first = cleaned.first {
            cleaned = first.uppercased() + cleaned.dropFirst()
        }
        
        return cleaned
    }
    
    // MARK: - Timer Extraction
    
    /// Try to extract a timer duration in seconds from a step
    private static func extractTimer(from text: String) -> Int? {
        let lower = text.lowercased()
        
        // Match patterns like "for 20 minutes", "for 5-7 mins", "30 seconds"
        let patterns = [
            #"(\d+)\s*(?:to|-)\s*(\d+)\s*(?:minutes?|mins?)"#,  // range: "5-7 minutes"
            #"(\d+)\s*(?:minutes?|mins?)"#,                       // single: "20 minutes"
            #"(\d+)\s*(?:hours?|hrs?)"#,                          // hours: "2 hours"
            #"(\d+)\s*(?:seconds?|secs?)"#                        // seconds: "30 seconds"
        ]
        
        for (index, pattern) in patterns.enumerated() {
            if let match = lower.range(of: pattern, options: .regularExpression) {
                let matched = String(lower[match])
                let numbers = matched.components(separatedBy: .decimalDigits.inverted)
                    .filter { !$0.isEmpty }
                    .compactMap { Int($0) }
                
                guard let first = numbers.first else { continue }
                
                switch index {
                case 0: // range of minutes - use the higher value
                    let high = numbers.count > 1 ? numbers[1] : first
                    return high * 60
                case 1: // minutes
                    return first * 60
                case 2: // hours
                    return first * 3600
                case 3: // seconds
                    return first
                default:
                    break
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Metadata Extraction
    
    private static func extractServings(from text: String) -> Int? {
        let lower = text.lowercased()
        let patterns = [
            #"serves?\s*:?\s*(\d+)"#,
            #"servings?\s*:?\s*(\d+)"#,
            #"makes?\s*:?\s*(\d+)"#,
            #"yield\s*:?\s*(\d+)"#,
            #"(\d+)\s*servings?"#
        ]
        
        for pattern in patterns {
            if let match = lower.range(of: pattern, options: .regularExpression) {
                let matched = String(lower[match])
                let number = matched.components(separatedBy: .decimalDigits.inverted)
                    .filter { !$0.isEmpty }
                    .compactMap { Int($0) }
                    .first
                if let n = number, n > 0, n <= 100 {
                    return n
                }
            }
        }
        
        return nil
    }
    
    private static func extractTimes(from text: String) -> (prep: Int, cook: Int) {
        let lower = text.lowercased()
        var prep = 0
        var cook = 0
        
        // Prep time
        let prepPatterns = [
            #"prep\s*(?:time)?\s*:?\s*(\d+)\s*(?:minutes?|mins?)"#,
            #"preparation\s*(?:time)?\s*:?\s*(\d+)\s*(?:minutes?|mins?)"#
        ]
        for pattern in prepPatterns {
            if let match = lower.range(of: pattern, options: .regularExpression) {
                let matched = String(lower[match])
                if let n = matched.components(separatedBy: .decimalDigits.inverted)
                    .filter({ !$0.isEmpty }).compactMap({ Int($0) }).first {
                    prep = n
                    break
                }
            }
        }
        
        // Cook time
        let cookPatterns = [
            #"cook\s*(?:time)?\s*:?\s*(\d+)\s*(?:minutes?|mins?)"#,
            #"cooking\s*(?:time)?\s*:?\s*(\d+)\s*(?:minutes?|mins?)"#,
            #"bake\s*(?:time)?\s*:?\s*(\d+)\s*(?:minutes?|mins?)"#,
            #"total\s*(?:time)?\s*:?\s*(\d+)\s*(?:minutes?|mins?)"#
        ]
        for pattern in cookPatterns {
            if let match = lower.range(of: pattern, options: .regularExpression) {
                let matched = String(lower[match])
                if let n = matched.components(separatedBy: .decimalDigits.inverted)
                    .filter({ !$0.isEmpty }).compactMap({ Int($0) }).first {
                    cook = n
                    break
                }
            }
        }
        
        return (prep, cook)
    }
}
