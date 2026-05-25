import Foundation
import SwiftUI

// MARK: - Category

enum RecipeCategory: String, CaseIterable, Codable, Identifiable {
    case breakfast = "Breakfast"
    case brunch = "Brunch"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case appetizers = "Appetizers"
    case sides = "Sides"
    case drinks = "Drinks & Cocktails"
    case sauces = "Sauces & Condiments"
    case baking = "Baking"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .breakfast:   return "sun.horizon.fill"
        case .brunch:      return "cup.and.saucer.fill"
        case .lunch:       return "fork.knife"
        case .dinner:      return "moon.stars.fill"
        case .appetizers:  return "leaf.fill"
        case .sides:       return "square.split.1x2.fill"
        case .drinks:      return "wineglass.fill"
        case .sauces:      return "drop.fill"
        case .baking:      return "birthday.cake.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast:   return Color(hex: "F4A261")
        case .brunch:      return Color(hex: "E9C46A")
        case .lunch:       return Color(hex: "2A9D8F")
        case .dinner:      return Color(hex: "264653")
        case .appetizers:  return Color(hex: "8AC926")
        case .sides:       return Color(hex: "6A994E")
        case .drinks:      return Color(hex: "E76F51")
        case .sauces:      return Color(hex: "BC6C25")
        case .baking:      return Color(hex: "D4A373")
        }
    }
    
    static func categoriesForTimeOfDay(_ hour: Int) -> [RecipeCategory] {
        switch hour {
        case 5...9:   return [.breakfast]
        case 10...11: return [.brunch, .breakfast]
        case 12...14: return [.lunch, .sides, .appetizers]
        case 15...16: return [.baking, .drinks, .appetizers]
        case 17...21: return [.dinner, .sides, .appetizers]
        case 22...23: return [.baking, .drinks]
        default:      return RecipeCategory.allCases
        }
    }
}

// MARK: - Sub-Category

enum RecipeSubCategory: String, CaseIterable, Codable, Identifiable {
    case quickMeal = "Quick Meal"
    case mealPrep = "Meal Prep"
    case comfortFood = "Comfort Food"
    case healthy = "Healthy"
    case snack = "Snack"
    case dessert = "Dessert"
    case holiday = "Holiday / Special Occasion"
    case kidFriendly = "Kid-Friendly"
    case onePot = "One-Pot"
    case glutenFree = "Gluten-Free"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case highProtein = "High Protein"
    case lowCarb = "Low Carb"
    case seafood = "Seafood"
    case grilling = "Grilling"
    case slowCooker = "Slow Cooker"
    case instantPot = "Instant Pot"
    case salad = "Salad"
    case soup = "Soup"
    case sandwich = "Sandwich"
    case pasta = "Pasta"
    case casserole = "Casserole"
    case stirFry = "Stir Fry"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .quickMeal:    return "bolt.fill"
        case .mealPrep:     return "tray.2.fill"
        case .comfortFood:  return "heart.fill"
        case .healthy:      return "leaf.fill"
        case .snack:        return "carrot.fill"
        case .dessert:      return "birthday.cake.fill"
        case .holiday:      return "star.fill"
        case .kidFriendly:  return "figure.and.child.holdinghands"
        case .onePot:       return "frying.pan.fill"
        case .glutenFree:   return "checkmark.seal.fill"
        case .vegetarian:   return "leaf.circle.fill"
        case .vegan:        return "leaf.arrow.circlepath"
        case .highProtein:  return "dumbbell.fill"
        case .lowCarb:      return "scalemass.fill"
        case .seafood:      return "fish.fill"
        case .grilling:     return "flame.fill"
        case .slowCooker:   return "timer"
        case .instantPot:   return "gauge.with.dots.needle.33percent"
        case .salad:        return "leaf.fill"
        case .soup:         return "mug.fill"
        case .sandwich:     return "square.split.2x1.fill"
        case .pasta:        return "fork.knife.circle.fill"
        case .casserole:    return "square.3.layers.3d.top.filled"
        case .stirFry:      return "frying.pan"
        case .other:        return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Difficulty

enum RecipeDifficulty: String, CaseIterable, Codable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case advanced = "Advanced"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .easy:     return .green
        case .medium:   return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Season

enum RecipeSeason: String, CaseIterable, Codable, Identifiable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
    case allYear = "All Year"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .spring:  return "leaf.fill"
        case .summer:  return "sun.max.fill"
        case .fall:    return "wind"
        case .winter:  return "snowflake"
        case .allYear: return "calendar"
        }
    }
    
    var months: [Int] {
        switch self {
        case .spring:  return [3, 4, 5]
        case .summer:  return [6, 7, 8]
        case .fall:    return [9, 10, 11]
        case .winter:  return [12, 1, 2]
        case .allYear: return Array(1...12)
        }
    }
    
    static func current() -> RecipeSeason {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:   return .spring
        case 6...8:   return .summer
        case 9...11:  return .fall
        default:      return .winter
        }
    }
}

// MARK: - Ingredient

struct Ingredient: Identifiable, Codable, Equatable {
    var id = UUID()
    var quantity: String
    var unit: String
    var name: String
    var substitution: String?
    var priceEstimate: Double?
    
    var displayText: String {
        let parts = [quantity, unit, name].filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }
    
    var normalizedName: String {
        name.lowercased().trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Preparation Step

struct PrepStep: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var timerSeconds: Int?
    
    var timerDisplay: String? {
        guard let seconds = timerSeconds, seconds > 0 else { return nil }
        let mins = seconds / 60
        let secs = seconds % 60
        if secs == 0 { return "\(mins) min" }
        return "\(mins)m \(secs)s"
    }
}

// MARK: - Cooking Log Entry

struct CookingLogEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var dayOfWeek: Int
    var hourOfDay: Int
    var rating: Int?
    
    init(date: Date = Date(), rating: Int? = nil) {
        self.date = date
        let calendar = Calendar.current
        self.dayOfWeek = calendar.component(.weekday, from: date)
        self.hourOfDay = calendar.component(.hour, from: date)
        self.rating = rating
    }
}

// MARK: - Recipe Version

struct RecipeVersion: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var ingredients: [Ingredient]
    var preparationSteps: [PrepStep]
    var cookingSteps: [PrepStep]
    var notes: String
    var dateCreated: Date
}

// MARK: - Meal Plan Entry

struct MealPlanEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var recipeID: UUID
    var date: Date
    var mealType: MealType
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
    }
}

// MARK: - Recipe

struct Recipe: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var category: RecipeCategory
    var subCategories: [RecipeSubCategory]
    var description: String
    var difficulty: RecipeDifficulty
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var servings: Int
    var ingredients: [Ingredient]
    var preparationSteps: [PrepStep]
    var cookingSteps: [PrepStep]
    var notes: String
    var isFavorite: Bool
    var collections: [String]
    var imageData: Data?
    var dateCreated: Date
    var dateModified: Date
    var rating: Int?
    var cookingLog: [CookingLogEntry]
    var seasons: [RecipeSeason]
    var versions: [RecipeVersion]
    var activeVersionID: UUID?
    
    var totalTimeMinutes: Int { prepTimeMinutes + cookTimeMinutes }
    
    var totalTimeDisplay: String {
        let total = totalTimeMinutes
        if total < 60 { return "\(total) min" }
        let hrs = total / 60
        let mins = total % 60
        if mins == 0 { return "\(hrs)h" }
        return "\(hrs)h \(mins)m"
    }
    
    var timesCookedTotal: Int { cookingLog.count }
    
    var lastCooked: Date? {
        cookingLog.max(by: { $0.date < $1.date })?.date
    }
    
    var averageRating: Double? {
        let rated = cookingLog.compactMap { $0.rating }
        guard !rated.isEmpty else {
            if let r = rating { return Double(r) }
            return nil
        }
        return Double(rated.reduce(0, +)) / Double(rated.count)
    }
    
    var estimatedCost: Double {
        ingredients.compactMap { $0.priceEstimate }.reduce(0, +)
    }
    
    var costPerServing: Double {
        guard servings > 0 else { return 0 }
        return estimatedCost / Double(servings)
    }
    
    func cookCountForWeekday(_ weekday: Int) -> Int {
        cookingLog.filter { $0.dayOfWeek == weekday }.count
    }
    
    func cookCountForHourRange(_ range: ClosedRange<Int>) -> Int {
        cookingLog.filter { range.contains($0.hourOfDay) }.count
    }
    
    var isSeasonalNow: Bool {
        if seasons.isEmpty || seasons.contains(.allYear) { return true }
        let currentMonth = Calendar.current.component(.month, from: Date())
        return seasons.contains(where: { $0.months.contains(currentMonth) })
    }
    
    static func blank() -> Recipe {
        Recipe(
            title: "", category: .dinner, subCategories: [], description: "",
            difficulty: .easy, prepTimeMinutes: 0, cookTimeMinutes: 0, servings: 4,
            ingredients: [], preparationSteps: [], cookingSteps: [], notes: "",
            isFavorite: false, collections: [], imageData: nil,
            dateCreated: Date(), dateModified: Date(), rating: nil, cookingLog: [],
            seasons: [.allYear], versions: [], activeVersionID: nil
        )
    }
}

// MARK: - Grocery Item

struct GroceryItem: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var quantities: [String]
    var isChecked: Bool = false
    var aisle: GroceryAisle
    var inPantry: Bool = false
}

enum GroceryAisle: String, CaseIterable, Codable {
    case produce = "Produce"
    case dairy = "Dairy & Eggs"
    case meat = "Meat & Seafood"
    case bakery = "Bakery & Bread"
    case pantry = "Pantry & Dry Goods"
    case spices = "Spices & Seasonings"
    case frozen = "Frozen"
    case canned = "Canned Goods"
    case condiments = "Condiments & Sauces"
    case beverages = "Beverages"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .produce:    return "leaf.fill"
        case .dairy:      return "cup.and.saucer.fill"
        case .meat:       return "fish.fill"
        case .bakery:     return "birthday.cake.fill"
        case .pantry:     return "archivebox.fill"
        case .spices:     return "flame.fill"
        case .frozen:     return "snowflake"
        case .canned:     return "cylinder.fill"
        case .condiments: return "drop.fill"
        case .beverages:  return "wineglass.fill"
        case .other:      return "cart.fill"
        }
    }
    
    static func detect(for ingredientName: String) -> GroceryAisle {
        let lower = ingredientName.lowercased()
        
        // Order matters: more specific matches first, broader categories last.
        // "pantry" must come before "beverages" so "baking soda" matches pantry, not "soda" in beverages.
        let map: [(GroceryAisle, [String])] = [
            (.produce, ["lettuce","tomato","onion","garlic","pepper","carrot","celery","potato","avocado","lemon","lime","orange","apple","banana","berry","berries","spinach","kale","cucumber","zucchini","mushroom","broccoli","cauliflower","corn","ginger","cilantro","parsley","basil","mint","scallion","jalapeno","cabbage","squash","fresh"]),
            (.dairy, ["milk","cream","butter","cheese","yogurt","egg","eggs","sour cream","ricotta","mozzarella","parmesan","cheddar","cream cheese"]),
            (.meat, ["chicken","beef","pork","steak","ground","turkey","bacon","sausage","ham","lamb","fish","salmon","shrimp","tuna","crab","lobster","pancetta","prosciutto","chorizo"]),
            (.spices, ["salt","pepper","cumin","paprika","cinnamon","oregano","thyme","rosemary","bay leaf","chili powder","cayenne","turmeric","nutmeg","cloves","coriander","seasoning","curry","sage","dill"]),
            (.condiments, ["ketchup","mustard","mayo","mayonnaise","soy sauce","hot sauce","sriracha","worcestershire","bbq sauce","salsa","ranch","dressing","teriyaki","hoisin","fish sauce","tahini"]),
            (.bakery, ["bread","bun","roll","tortilla","pita","naan","bagel","croissant","baguette"]),
            (.canned, ["canned","tomato sauce","tomato paste","diced tomatoes","broth","stock","coconut milk","chickpeas"]),
            (.frozen, ["frozen","ice cream"]),
            (.pantry, ["flour","sugar","rice","pasta","noodle","oat","baking soda","baking powder","yeast","cornstarch","panko","oil","olive oil","vinegar","honey","maple syrup","vanilla","chocolate","cocoa","nuts","almond","walnut","pecan","peanut","coconut","extract"]),
            (.beverages, ["juice","wine","beer","coffee","tea"])
        ]
        
        for (aisle, words) in map {
            // Check multi-word phrases first (longer matches are more specific)
            let sortedWords = words.sorted { $0.count > $1.count }
            if sortedWords.contains(where: { lower.contains($0) }) { return aisle }
        }
        return .other
    }
}

// MARK: - Pantry Item

struct PantryItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var dateAdded: Date = Date()
    
    var normalizedName: String {
        name.lowercased().trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}
