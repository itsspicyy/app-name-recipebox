import Foundation

class DifficultyEstimator {
    
    private static let advancedTechniques = [
        "deglaze", "julienne", "brunoise", "chiffonade", "temper", "tempering",
        "caramelize", "flambe", "flambé", "braise", "blanch", "poach",
        "emulsify", "fold", "proof", "knead", "ferment", "cure",
        "sous vide", "baste", "reduce", "clarify", "fillet", "debone",
        "truss", "score", "blind bake", "double boiler", "water bath",
        "candy thermometer", "deep fry", "confit", "roux"
    ]
    
    private static let mediumTechniques = [
        "marinate", "sauté", "saute", "roast", "grill", "broil",
        "steam", "stir fry", "sear", "simmer", "zest", "mince",
        "dice", "whisk", "cream", "beat", "separate", "strain"
    ]
    
    static func suggest(
        ingredientCount: Int,
        prepStepCount: Int,
        cookStepCount: Int,
        totalTimeMinutes: Int,
        stepTexts: [String]
    ) -> RecipeDifficulty {
        var score = 0
        
        // Ingredient count
        if ingredientCount > 15 { score += 3 }
        else if ingredientCount > 8 { score += 1 }
        
        // Step count
        let totalSteps = prepStepCount + cookStepCount
        if totalSteps > 12 { score += 3 }
        else if totalSteps > 6 { score += 1 }
        
        // Time
        if totalTimeMinutes > 120 { score += 3 }
        else if totalTimeMinutes > 60 { score += 1 }
        
        // Technique analysis
        let allText = stepTexts.joined(separator: " ").lowercased()
        
        let advancedCount = advancedTechniques.filter { allText.contains($0) }.count
        score += advancedCount * 2
        
        let mediumCount = mediumTechniques.filter { allText.contains($0) }.count
        score += mediumCount
        
        if score >= 6 { return .advanced }
        if score >= 3 { return .medium }
        return .easy
    }
}
