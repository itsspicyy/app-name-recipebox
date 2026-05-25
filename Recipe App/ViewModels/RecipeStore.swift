import Foundation
import SwiftUI
import Combine

class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var collections: [String] = ["Favorites"]
    @Published var searchText: String = ""
    @Published var selectedCategory: RecipeCategory? = nil
    @Published var selectedSubCategory: RecipeSubCategory? = nil
    @Published var groceryList: [GroceryItem] = []
    @Published var grocerySourceRecipes: [UUID] = []
    @Published var pantryItems: [PantryItem] = []
    @Published var mealPlan: [MealPlanEntry] = []
    
    init() { loadRecipes(); loadCollections(); loadPantry(); loadMealPlan() }
    
    var filteredRecipes: [Recipe] {
        var result = recipes
        if let cat = selectedCategory { result = result.filter { $0.category == cat } }
        if let sub = selectedSubCategory { result = result.filter { $0.subCategories.contains(sub) } }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter { r in
                r.title.lowercased().contains(q) || r.description.lowercased().contains(q) ||
                r.ingredients.contains(where: { $0.name.lowercased().contains(q) })
            }
        }
        return result.sorted { $0.dateModified > $1.dateModified }
    }
    var favoriteRecipes: [Recipe] { recipes.filter { $0.isFavorite } }
    func recipesInCollection(_ n: String) -> [Recipe] { recipes.filter { $0.collections.contains(n) } }
    var mealSuggestions: [MealSuggestionEngine.ScoredRecipe] { MealSuggestionEngine.suggest(from: recipes, limit: 3) }
    var topSuggestion: MealSuggestionEngine.ScoredRecipe? { MealSuggestionEngine.topSuggestion(from: recipes) }
    
    func addRecipe(_ recipe: Recipe) { var r = recipe; r.dateCreated = Date(); r.dateModified = Date(); recipes.append(r); saveRecipes() }
    func updateRecipe(_ recipe: Recipe) { guard let i = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }; var u = recipe; u.dateModified = Date(); recipes[i] = u; saveRecipes() }
    func deleteRecipe(_ recipe: Recipe) { recipes.removeAll { $0.id == recipe.id }; saveRecipes() }
    func toggleFavorite(_ recipe: Recipe) { guard let i = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }; recipes[i].isFavorite.toggle(); saveRecipes() }
    func rateRecipe(_ recipe: Recipe, rating: Int) { guard let i = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }; recipes[i].rating = rating; saveRecipes() }
    func logCookingSession(for recipe: Recipe, rating: Int? = nil) {
        guard let i = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[i].cookingLog.append(CookingLogEntry(date: Date(), rating: rating))
        if let r = rating { recipes[i].rating = r }; saveRecipes()
    }
    func importRecipe(_ recipe: Recipe) { if recipes.contains(where: { $0.title == recipe.title }) { var r = recipe; r.title += " (Shared)"; addRecipe(r) } else { addRecipe(recipe) } }
    
    func saveVersion(of recipe: Recipe, name: String) {
        guard let i = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        let v = RecipeVersion(name: name, ingredients: recipe.ingredients, preparationSteps: recipe.preparationSteps, cookingSteps: recipe.cookingSteps, notes: recipe.notes, dateCreated: Date())
        recipes[i].versions.append(v); saveRecipes()
    }
    func loadVersion(_ version: RecipeVersion, into recipeID: UUID) {
        guard let i = recipes.firstIndex(where: { $0.id == recipeID }) else { return }
        recipes[i].ingredients = version.ingredients; recipes[i].preparationSteps = version.preparationSteps
        recipes[i].cookingSteps = version.cookingSteps; recipes[i].notes = version.notes
        recipes[i].activeVersionID = version.id; recipes[i].dateModified = Date(); saveRecipes()
    }
    
    func addCollection(_ n: String) { guard !n.isEmpty, !collections.contains(n) else { return }; collections.append(n); saveCollections() }
    func removeCollection(_ n: String) { collections.removeAll { $0 == n }; for i in recipes.indices { recipes[i].collections.removeAll { $0 == n } }; saveCollections(); saveRecipes() }
    func addRecipeToCollection(_ r: Recipe, collection: String) { guard let i = recipes.firstIndex(where: { $0.id == r.id }) else { return }; if !recipes[i].collections.contains(collection) { recipes[i].collections.append(collection); saveRecipes() } }
    func removeRecipeFromCollection(_ r: Recipe, collection: String) { guard let i = recipes.firstIndex(where: { $0.id == r.id }) else { return }; recipes[i].collections.removeAll { $0 == collection }; saveRecipes() }
    
    func scaledIngredients(for recipe: Recipe, targetServings: Int) -> [Ingredient] {
        guard recipe.servings > 0 else { return recipe.ingredients }
        let f = Double(targetServings) / Double(recipe.servings)
        return recipe.ingredients.map { var s = $0; s.quantity = FractionHelper.scale($0.quantity, by: f); return s }
    }
    
    func generateGroceryList(for selected: [Recipe]) {
        grocerySourceRecipes = selected.map { $0.id }
        var merged: [String: GroceryItem] = [:]
        for recipe in selected { for ing in recipe.ingredients {
            let key = ing.normalizedName; let qty = [ing.quantity, ing.unit].filter { !$0.isEmpty }.joined(separator: " ")
            if var ex = merged[key] { if !qty.isEmpty { ex.quantities.append(qty) }; merged[key] = ex }
            else { merged[key] = GroceryItem(name: ing.name, quantities: qty.isEmpty ? [] : [qty], aisle: GroceryAisle.detect(for: ing.name), inPantry: isInPantry(ing.name)) }
        }}
        groceryList = merged.values.sorted { $0.aisle.rawValue < $1.aisle.rawValue }
    }
    func toggleGroceryItem(_ item: GroceryItem) { guard let i = groceryList.firstIndex(where: { $0.id == item.id }) else { return }; groceryList[i].isChecked.toggle() }
    func clearGroceryList() { groceryList = []; grocerySourceRecipes = [] }
    
    func isInPantry(_ name: String) -> Bool {
        let n = name.lowercased().trimmingCharacters(in: .whitespaces)
        return pantryItems.contains(where: { n.contains($0.normalizedName) || $0.normalizedName.contains(n) })
    }
    func addPantryItem(_ name: String) { guard !name.isEmpty else { return }; let item = PantryItem(name: name); if !pantryItems.contains(where: { $0.normalizedName == item.normalizedName }) { pantryItems.append(item); savePantry() } }
    func removePantryItem(_ item: PantryItem) { pantryItems.removeAll { $0.id == item.id }; savePantry() }
    
    func addToMealPlan(recipeID: UUID, date: Date, mealType: MealPlanEntry.MealType) { mealPlan.append(MealPlanEntry(recipeID: recipeID, date: date, mealType: mealType)); saveMealPlan() }
    func removeMealPlanEntry(_ entry: MealPlanEntry) { mealPlan.removeAll { $0.id == entry.id }; saveMealPlan() }
    func mealPlanEntries(for date: Date) -> [MealPlanEntry] { mealPlan.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.sorted { $0.mealType.rawValue < $1.mealType.rawValue } }
    func recipeForEntry(_ entry: MealPlanEntry) -> Recipe? { recipes.first(where: { $0.id == entry.recipeID }) }
    func generateGroceryListFromMealPlan(for week: [Date]) {
        let entries = mealPlan.filter { e in week.contains(where: { Calendar.current.isDate($0, inSameDayAs: e.date) }) }
        generateGroceryList(for: recipes.filter { r in entries.contains(where: { $0.recipeID == r.id }) })
    }
    
    private func docURL(_ n: String) -> URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(n) }
    private func saveRecipes() { save(recipes, to: "recipes.json") }
    private func loadRecipes() { recipes = load("recipes.json") ?? [] }
    private func saveCollections() { save(collections, to: "collections.json") }
    private func loadCollections() { collections = load("collections.json") ?? ["Favorites"] }
    private func savePantry() { save(pantryItems, to: "pantry.json") }
    private func loadPantry() { pantryItems = load("pantry.json") ?? [] }
    private func saveMealPlan() { save(mealPlan, to: "mealplan.json") }
    private func loadMealPlan() { mealPlan = load("mealplan.json") ?? [] }
    private func save<T: Encodable>(_ v: T, to f: String) { guard let d = try? JSONEncoder().encode(v) else { return }; try? d.write(to: docURL(f), options: .atomic) }
    private func load<T: Decodable>(_ f: String) -> T? { let u = docURL(f); guard FileManager.default.fileExists(atPath: u.path), let d = try? Data(contentsOf: u) else { return nil }; return try? JSONDecoder().decode(T.self, from: d) }
}
