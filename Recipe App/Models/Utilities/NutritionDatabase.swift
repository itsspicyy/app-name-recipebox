import Foundation

struct NutritionInfo {
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
}

struct RecipeNutrition {
    let totalCalories: Int
    let totalProtein: Int
    let totalCarbs: Int
    let totalFat: Int
    let perServing: (calories: Int, protein: Int, carbs: Int, fat: Int)
}

class NutritionDatabase {
    
    /// Estimate nutrition for a full recipe
    static func estimate(for recipe: Recipe) -> RecipeNutrition {
        var totalCal: Double = 0
        var totalPro: Double = 0
        var totalCarb: Double = 0
        var totalFat: Double = 0
        
        for ingredient in recipe.ingredients {
            let grams = estimateGrams(quantity: ingredient.quantity, unit: ingredient.unit, name: ingredient.name)
            if let info = lookup(ingredient.name) {
                let factor = grams / 100.0
                totalCal += info.caloriesPer100g * factor
                totalPro += info.proteinPer100g * factor
                totalCarb += info.carbsPer100g * factor
                totalFat += info.fatPer100g * factor
            }
        }
        
        let servings = max(recipe.servings, 1)
        return RecipeNutrition(
            totalCalories: Int(totalCal),
            totalProtein: Int(totalPro),
            totalCarbs: Int(totalCarb),
            totalFat: Int(totalFat),
            perServing: (
                calories: Int(totalCal / Double(servings)),
                protein: Int(totalPro / Double(servings)),
                carbs: Int(totalCarb / Double(servings)),
                fat: Int(totalFat / Double(servings))
            )
        )
    }
    
    /// Convert quantity+unit to approximate grams
    private static func estimateGrams(quantity: String, unit: String, name: String) -> Double {
        let qty = FractionHelper.toDouble(quantity) ?? 1.0
        let u = unit.lowercased().trimmingCharacters(in: .punctuationCharacters)
        
        switch u {
        case "g", "gram", "grams":           return qty
        case "kg", "kilogram", "kilograms":  return qty * 1000
        case "oz", "ounce", "ounces":        return qty * 28.35
        case "lb", "lbs", "pound", "pounds": return qty * 453.6
        case "cup", "cups", "c":             return qty * cupToGrams(for: name)
        case "tbsp", "tablespoon", "tablespoons", "tbs": return qty * 15
        case "tsp", "teaspoon", "teaspoons", "ts":       return qty * 5
        case "ml", "milliliter", "milliliters":           return qty
        case "l", "liter", "liters":                      return qty * 1000
        case "pinch", "dash":                return qty * 1
        default:
            // Unitless items (e.g. "2 eggs", "3 cloves garlic")
            return qty * unitlessGrams(for: name)
        }
    }
    
    /// Approximate grams per cup for common ingredients
    private static func cupToGrams(for name: String) -> Double {
        let lower = name.lowercased()
        if lower.contains("flour")    { return 125 }
        if lower.contains("sugar")    { return 200 }
        if lower.contains("butter")   { return 227 }
        if lower.contains("rice")     { return 185 }
        if lower.contains("milk")     { return 244 }
        if lower.contains("cream")    { return 240 }
        if lower.contains("oil")      { return 218 }
        if lower.contains("honey")    { return 340 }
        if lower.contains("oat")      { return 90 }
        if lower.contains("cheese")   { return 113 }
        if lower.contains("yogurt")   { return 245 }
        if lower.contains("water")    { return 237 }
        if lower.contains("broth")    { return 237 }
        return 150 // generic default
    }
    
    /// Approximate grams for unitless items
    private static func unitlessGrams(for name: String) -> Double {
        let lower = name.lowercased()
        if lower.contains("egg")      { return 50 }
        if lower.contains("banana")   { return 118 }
        if lower.contains("apple")    { return 182 }
        if lower.contains("lemon")    { return 58 }
        if lower.contains("lime")     { return 44 }
        if lower.contains("orange")   { return 131 }
        if lower.contains("garlic") && lower.contains("clove") { return 3 }
        if lower.contains("onion")    { return 150 }
        if lower.contains("tomato")   { return 123 }
        if lower.contains("potato")   { return 150 }
        if lower.contains("avocado")  { return 150 }
        if lower.contains("chicken breast") { return 174 }
        if lower.contains("slice")    { return 30 }
        return 100
    }
    
    /// Look up nutrition info by ingredient name keyword matching
    static func lookup(_ name: String) -> NutritionInfo? {
        let lower = name.lowercased()
        
        for (keywords, info) in database {
            if keywords.contains(where: { lower.contains($0) }) {
                return info
            }
        }
        return nil
    }
    
    // cal, protein, carbs, fat per 100g
    private static let database: [([String], NutritionInfo)] = [
        // Proteins
        (["chicken breast"], NutritionInfo(caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6)),
        (["chicken thigh", "chicken leg", "chicken"], NutritionInfo(caloriesPer100g: 209, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 11)),
        (["ground beef", "beef"], NutritionInfo(caloriesPer100g: 250, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 15)),
        (["steak"], NutritionInfo(caloriesPer100g: 271, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 18)),
        (["pork"], NutritionInfo(caloriesPer100g: 242, proteinPer100g: 27, carbsPer100g: 0, fatPer100g: 14)),
        (["bacon", "pancetta"], NutritionInfo(caloriesPer100g: 541, proteinPer100g: 37, carbsPer100g: 1, fatPer100g: 42)),
        (["salmon"], NutritionInfo(caloriesPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13)),
        (["shrimp"], NutritionInfo(caloriesPer100g: 99, proteinPer100g: 24, carbsPer100g: 0, fatPer100g: 0.3)),
        (["tuna"], NutritionInfo(caloriesPer100g: 132, proteinPer100g: 28, carbsPer100g: 0, fatPer100g: 1)),
        (["turkey"], NutritionInfo(caloriesPer100g: 189, proteinPer100g: 29, carbsPer100g: 0, fatPer100g: 7)),
        (["egg"], NutritionInfo(caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1, fatPer100g: 11)),
        (["tofu"], NutritionInfo(caloriesPer100g: 76, proteinPer100g: 8, carbsPer100g: 2, fatPer100g: 4.8)),
        (["sausage"], NutritionInfo(caloriesPer100g: 301, proteinPer100g: 12, carbsPer100g: 2, fatPer100g: 27)),
        
        // Dairy
        (["butter"], NutritionInfo(caloriesPer100g: 717, proteinPer100g: 0.9, carbsPer100g: 0, fatPer100g: 81)),
        (["cream cheese"], NutritionInfo(caloriesPer100g: 342, proteinPer100g: 6, carbsPer100g: 4, fatPer100g: 34)),
        (["cheddar"], NutritionInfo(caloriesPer100g: 403, proteinPer100g: 25, carbsPer100g: 1, fatPer100g: 33)),
        (["mozzarella"], NutritionInfo(caloriesPer100g: 280, proteinPer100g: 28, carbsPer100g: 3, fatPer100g: 17)),
        (["parmesan", "pecorino"], NutritionInfo(caloriesPer100g: 431, proteinPer100g: 38, carbsPer100g: 4, fatPer100g: 29)),
        (["cheese"], NutritionInfo(caloriesPer100g: 350, proteinPer100g: 25, carbsPer100g: 2, fatPer100g: 28)),
        (["milk"], NutritionInfo(caloriesPer100g: 42, proteinPer100g: 3.4, carbsPer100g: 5, fatPer100g: 1)),
        (["heavy cream", "whipping cream", "cream"], NutritionInfo(caloriesPer100g: 340, proteinPer100g: 2, carbsPer100g: 3, fatPer100g: 36)),
        (["sour cream"], NutritionInfo(caloriesPer100g: 198, proteinPer100g: 2.4, carbsPer100g: 4.6, fatPer100g: 19.4)),
        (["yogurt"], NutritionInfo(caloriesPer100g: 59, proteinPer100g: 10, carbsPer100g: 4, fatPer100g: 0.7)),
        
        // Grains & starches
        (["flour"], NutritionInfo(caloriesPer100g: 364, proteinPer100g: 10, carbsPer100g: 76, fatPer100g: 1)),
        (["rice"], NutritionInfo(caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3)),
        (["pasta", "spaghetti", "noodle", "penne", "linguine"], NutritionInfo(caloriesPer100g: 131, proteinPer100g: 5, carbsPer100g: 25, fatPer100g: 1.1)),
        (["bread"], NutritionInfo(caloriesPer100g: 265, proteinPer100g: 9, carbsPer100g: 49, fatPer100g: 3.2)),
        (["tortilla"], NutritionInfo(caloriesPer100g: 312, proteinPer100g: 8, carbsPer100g: 52, fatPer100g: 8)),
        (["oat"], NutritionInfo(caloriesPer100g: 389, proteinPer100g: 17, carbsPer100g: 66, fatPer100g: 7)),
        (["potato"], NutritionInfo(caloriesPer100g: 77, proteinPer100g: 2, carbsPer100g: 17, fatPer100g: 0.1)),
        (["cornstarch"], NutritionInfo(caloriesPer100g: 381, proteinPer100g: 0.3, carbsPer100g: 91, fatPer100g: 0)),
        
        // Vegetables
        (["onion"], NutritionInfo(caloriesPer100g: 40, proteinPer100g: 1.1, carbsPer100g: 9, fatPer100g: 0.1)),
        (["garlic"], NutritionInfo(caloriesPer100g: 149, proteinPer100g: 6.4, carbsPer100g: 33, fatPer100g: 0.5)),
        (["tomato"], NutritionInfo(caloriesPer100g: 18, proteinPer100g: 0.9, carbsPer100g: 3.9, fatPer100g: 0.2)),
        (["carrot"], NutritionInfo(caloriesPer100g: 41, proteinPer100g: 0.9, carbsPer100g: 10, fatPer100g: 0.2)),
        (["broccoli"], NutritionInfo(caloriesPer100g: 34, proteinPer100g: 2.8, carbsPer100g: 7, fatPer100g: 0.4)),
        (["spinach"], NutritionInfo(caloriesPer100g: 23, proteinPer100g: 2.9, carbsPer100g: 3.6, fatPer100g: 0.4)),
        (["bell pepper", "pepper"], NutritionInfo(caloriesPer100g: 31, proteinPer100g: 1, carbsPer100g: 6, fatPer100g: 0.3)),
        (["mushroom"], NutritionInfo(caloriesPer100g: 22, proteinPer100g: 3.1, carbsPer100g: 3.3, fatPer100g: 0.3)),
        (["celery"], NutritionInfo(caloriesPer100g: 16, proteinPer100g: 0.7, carbsPer100g: 3, fatPer100g: 0.2)),
        (["lettuce"], NutritionInfo(caloriesPer100g: 15, proteinPer100g: 1.4, carbsPer100g: 2.9, fatPer100g: 0.2)),
        (["cucumber"], NutritionInfo(caloriesPer100g: 16, proteinPer100g: 0.7, carbsPer100g: 3.6, fatPer100g: 0.1)),
        (["avocado"], NutritionInfo(caloriesPer100g: 160, proteinPer100g: 2, carbsPer100g: 9, fatPer100g: 15)),
        (["corn"], NutritionInfo(caloriesPer100g: 86, proteinPer100g: 3.3, carbsPer100g: 19, fatPer100g: 1.4)),
        (["zucchini"], NutritionInfo(caloriesPer100g: 17, proteinPer100g: 1.2, carbsPer100g: 3.1, fatPer100g: 0.3)),
        
        // Fruits
        (["banana"], NutritionInfo(caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3)),
        (["apple"], NutritionInfo(caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2)),
        (["lemon", "lime"], NutritionInfo(caloriesPer100g: 29, proteinPer100g: 1.1, carbsPer100g: 9, fatPer100g: 0.3)),
        (["orange"], NutritionInfo(caloriesPer100g: 47, proteinPer100g: 0.9, carbsPer100g: 12, fatPer100g: 0.1)),
        (["strawberr", "blueberr", "raspberr", "berry", "berries"], NutritionInfo(caloriesPer100g: 57, proteinPer100g: 1.1, carbsPer100g: 14, fatPer100g: 0.5)),
        
        // Fats & oils
        (["olive oil", "vegetable oil", "canola oil", "oil"], NutritionInfo(caloriesPer100g: 884, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100)),
        (["coconut oil"], NutritionInfo(caloriesPer100g: 862, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100)),
        
        // Sweeteners
        (["sugar"], NutritionInfo(caloriesPer100g: 387, proteinPer100g: 0, carbsPer100g: 100, fatPer100g: 0)),
        (["honey"], NutritionInfo(caloriesPer100g: 304, proteinPer100g: 0.3, carbsPer100g: 82, fatPer100g: 0)),
        (["maple syrup"], NutritionInfo(caloriesPer100g: 260, proteinPer100g: 0, carbsPer100g: 67, fatPer100g: 0)),
        
        // Canned / sauces
        (["tomato sauce", "tomato paste"], NutritionInfo(caloriesPer100g: 29, proteinPer100g: 1.3, carbsPer100g: 6, fatPer100g: 0.2)),
        (["soy sauce"], NutritionInfo(caloriesPer100g: 53, proteinPer100g: 8, carbsPer100g: 5, fatPer100g: 0)),
        (["broth", "stock"], NutritionInfo(caloriesPer100g: 7, proteinPer100g: 1, carbsPer100g: 0.3, fatPer100g: 0.2)),
        
        // Nuts & legumes
        (["almond"], NutritionInfo(caloriesPer100g: 579, proteinPer100g: 21, carbsPer100g: 22, fatPer100g: 50)),
        (["peanut"], NutritionInfo(caloriesPer100g: 567, proteinPer100g: 26, carbsPer100g: 16, fatPer100g: 49)),
        (["walnut"], NutritionInfo(caloriesPer100g: 654, proteinPer100g: 15, carbsPer100g: 14, fatPer100g: 65)),
        (["black bean", "kidney bean", "beans", "chickpea", "lentil"], NutritionInfo(caloriesPer100g: 132, proteinPer100g: 9, carbsPer100g: 24, fatPer100g: 0.5)),
        
        // Chocolate & baking
        (["chocolate", "cocoa"], NutritionInfo(caloriesPer100g: 546, proteinPer100g: 5, carbsPer100g: 60, fatPer100g: 31)),
        (["vanilla"], NutritionInfo(caloriesPer100g: 288, proteinPer100g: 0, carbsPer100g: 13, fatPer100g: 0)),
        (["baking soda", "baking powder"], NutritionInfo(caloriesPer100g: 0, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 0)),
        
        // Spices (negligible nutrition at typical amounts)
        (["salt","pepper","cumin","paprika","cinnamon","oregano","thyme","rosemary","curry","chili powder","cayenne","turmeric","nutmeg"], NutritionInfo(caloriesPer100g: 0, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 0)),
        
        // Beverages
        (["wine"], NutritionInfo(caloriesPer100g: 83, proteinPer100g: 0, carbsPer100g: 2.6, fatPer100g: 0)),
        (["beer"], NutritionInfo(caloriesPer100g: 43, proteinPer100g: 0.5, carbsPer100g: 3.6, fatPer100g: 0)),
        
        // Coconut
        (["coconut milk"], NutritionInfo(caloriesPer100g: 197, proteinPer100g: 2.2, carbsPer100g: 2.8, fatPer100g: 21)),
        (["coconut"], NutritionInfo(caloriesPer100g: 354, proteinPer100g: 3.3, carbsPer100g: 15, fatPer100g: 33)),
    ]
}
