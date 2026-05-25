import Foundation

class MealSuggestionEngine {
    
    struct ScoredRecipe {
        let recipe: Recipe
        let score: Double
        let reason: String
    }
    
    static func suggest(from recipes: [Recipe], limit: Int = 3) -> [ScoredRecipe] {
        guard !recipes.isEmpty else { return [] }
        
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        
        var scored: [ScoredRecipe] = []
        
        for recipe in recipes {
            var score: Double = 0
            var reasons: [String] = []
            
            // Time-of-day match
            let timeScore = timeOfDayScore(recipe: recipe, hour: currentHour)
            score += timeScore * 40
            if timeScore > 0 { reasons.append(timeOfDayLabel(hour: currentHour)) }
            
            // Day-of-week pattern
            let dayCount = recipe.cookCountForWeekday(currentWeekday)
            if dayCount > 0 {
                score += min(Double(dayCount) / 3.0, 1.0) * 30
                let dayName = calendar.weekdaySymbols[currentWeekday - 1]
                reasons.append("You often make this on \(dayName)s")
            }
            
            // Hour-range pattern
            let hourRange = hourRangeForTime(currentHour)
            let hourCount = recipe.cookCountForHourRange(hourRange)
            if hourCount > 0 { score += min(Double(hourCount) / 3.0, 1.0) * 20 }
            
            // Seasonal boost
            if recipe.isSeasonalNow {
                score += 12
                let currentSeason = RecipeSeason.current()
                if recipe.seasons.contains(currentSeason) && currentSeason != .allYear {
                    reasons.append("Perfect for \(currentSeason.rawValue)")
                }
            } else {
                score -= 10 // penalize out-of-season
            }
            
            // Rating boost
            if let avg = recipe.averageRating {
                score += (avg / 5.0) * 15
                if avg >= 4.0 { reasons.append("Highly rated") }
            }
            
            // Favorite boost
            if recipe.isFavorite { score += 10 }
            
            // Recency
            if let last = recipe.lastCooked {
                let daysSince = calendar.dateComponents([.day], from: last, to: now).day ?? 0
                if daysSince < 2 { score -= 20 }
                else if daysSince > 14 {
                    score += 5
                    reasons.append("Haven't made in a while")
                }
            } else if recipe.cookingLog.isEmpty {
                score += 3
                reasons.append("You haven't tried this yet")
            }
            
            // Category match
            if RecipeCategory.categoriesForTimeOfDay(currentHour).contains(recipe.category) {
                score += 15
            }
            
            let reason = reasons.isEmpty ? "Recommended for you" : reasons.first ?? "Recommended for you"
            scored.append(ScoredRecipe(recipe: recipe, score: score, reason: reason))
        }
        
        return Array(scored.sorted { $0.score > $1.score }.prefix(limit))
    }
    
    static func topSuggestion(from recipes: [Recipe]) -> ScoredRecipe? {
        suggest(from: recipes, limit: 1).first
    }
    
    private static func timeOfDayScore(recipe: Recipe, hour: Int) -> Double {
        let appropriate = RecipeCategory.categoriesForTimeOfDay(hour)
        if appropriate.contains(recipe.category) { return 1.0 }
        if hour >= 12 && recipe.subCategories.contains(where: { $0 == .dessert || $0 == .snack }) { return 0.5 }
        return 0.0
    }
    
    private static func timeOfDayLabel(hour: Int) -> String {
        switch hour {
        case 5...9:   return "Perfect for breakfast"
        case 10...11: return "Great for brunch"
        case 12...14: return "Good for lunch"
        case 15...16: return "Afternoon treat"
        case 17...21: return "Great for dinner"
        default:      return "Suggested for you"
        }
    }
    
    private static func hourRangeForTime(_ hour: Int) -> ClosedRange<Int> {
        switch hour {
        case 5...9: return 5...9
        case 10...11: return 10...11
        case 12...14: return 12...14
        case 15...16: return 15...16
        case 17...21: return 17...21
        default: return 22...23
        }
    }
}
