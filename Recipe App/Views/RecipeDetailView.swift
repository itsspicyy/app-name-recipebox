import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject var store: RecipeStore
    @State var recipe: Recipe
    @State private var adjustedServings: Int
    @State private var showCookingMode = false
    @State private var showEditSheet = false
    @State private var showCollectionPicker = false
    @State private var showDeleteAlert = false
    @State private var showCookingLog = false
    @State private var showPostCookRating = false
    @State private var showVersions = false
    @State private var saveVersionName = ""
    @State private var showSaveVersion = false
    @State private var showNutrition = false
    @Environment(\.dismiss) var dismiss
    
    init(recipe: Recipe) { _recipe = State(initialValue: recipe); _adjustedServings = State(initialValue: recipe.servings) }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage
                VStack(alignment: .leading, spacing: 24) {
                    headerSection; quickInfoBar; ratingSection
                    
                    // Nutrition & cost row
                    nutritionCostRow
                    
                    Divider()
                    servingAdjuster; ingredientsSection
                    if !recipe.preparationSteps.isEmpty { stepsSection(title: "Preparation", steps: recipe.preparationSteps) }
                    if !recipe.cookingSteps.isEmpty { stepsSection(title: "Cooking Steps", steps: recipe.cookingSteps) }
                    if !recipe.notes.isEmpty { notesSection }
                    if !recipe.seasons.isEmpty && !recipe.seasons.contains(.allYear) { seasonsSection }
                    if !recipe.versions.isEmpty { versionsSection }
                    if !recipe.cookingLog.isEmpty { cookingLogSection }
                    cookButton
                }.padding(.horizontal).padding(.top, 20).padding(.bottom, 40)
            }
        }
        .background(Color(hex: "F8F6F0"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { RecipeLinkHelper.share(recipe) } label: { Label("Share Recipe", systemImage: "square.and.arrow.up") }
                    Button { store.toggleFavorite(recipe); recipe.isFavorite.toggle() } label: { Label(recipe.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: recipe.isFavorite ? "heart.slash" : "heart") }
                    Button { showCollectionPicker = true } label: { Label("Add to Collection", systemImage: "folder.badge.plus") }
                    Button { showEditSheet = true } label: { Label("Edit Recipe", systemImage: "pencil") }
                    Button { showSaveVersion = true } label: { Label("Save as Version", systemImage: "doc.badge.plus") }
                    Button { showPostCookRating = true } label: { Label("Log as Cooked", systemImage: "checkmark.circle") }
                    if !recipe.cookingLog.isEmpty { Button { showCookingLog = true } label: { Label("Cooking History", systemImage: "clock.arrow.circlepath") } }
                    Divider()
                    Button(role: .destructive) { showDeleteAlert = true } label: { Label("Delete Recipe", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle").font(.title3) }
            }
        }
        .alert("Delete Recipe?", isPresented: $showDeleteAlert) { Button("Delete", role: .destructive) { store.deleteRecipe(recipe); dismiss() }; Button("Cancel", role: .cancel) {} } message: { Text("This cannot be undone.") }
        .alert("Log as Cooked", isPresented: $showPostCookRating) {
            Button("No Rating") { store.logCookingSession(for: recipe); refreshRecipe() }
            ForEach(1...5, id: \.self) { r in Button("⭐️ \(r)") { store.logCookingSession(for: recipe, rating: r); refreshRecipe() } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Rate this session (optional)") }
        .alert("Save Version", isPresented: $showSaveVersion) {
            TextField("e.g. Low-Sodium", text: $saveVersionName)
            Button("Save") { store.saveVersion(of: recipe, name: saveVersionName); saveVersionName = ""; refreshRecipe() }
            Button("Cancel", role: .cancel) { saveVersionName = "" }
        } message: { Text("Name this version") }
        .sheet(isPresented: $showCollectionPicker) { collectionPickerSheet }
        .sheet(isPresented: $showCookingLog) { cookingLogSheet }
        .sheet(isPresented: $showVersions) { versionsSheet }
        .fullScreenCover(isPresented: $showCookingMode) { CookingModeView(recipe: recipe) }
        .sheet(isPresented: $showEditSheet, onDismiss: { refreshRecipe() }) { AddRecipeView(existingRecipe: recipe) }
    }
    
    private func refreshRecipe() { if let u = store.recipes.first(where: { $0.id == recipe.id }) { recipe = u; adjustedServings = u.servings } }
    
    private var heroImage: some View {
        Group {
            if let d = recipe.imageData, let img = UIImage(data: d) { Image(uiImage: img).resizable().scaledToFill().frame(height: 260).clipped() }
            else { ZStack { LinearGradient(colors: [recipe.category.color.opacity(0.3), recipe.category.color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing); Image(systemName: recipe.category.icon).font(.system(size: 60)).foregroundStyle(recipe.category.color.opacity(0.4)) }.frame(height: 200) }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recipe.title).font(.title.weight(.bold))
                Spacer()
                Button { RecipeLinkHelper.share(recipe) } label: { Image(systemName: "square.and.arrow.up").font(.title3).foregroundStyle(Color(hex: "2A9D8F")) }
                if recipe.isFavorite { Image(systemName: "heart.fill").foregroundStyle(.red) }
            }
            if !recipe.description.isEmpty { Text(recipe.description).font(.body).foregroundStyle(.secondary) }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    tag(recipe.category.rawValue, color: recipe.category.color)
                    ForEach(recipe.subCategories) { s in tag(s.rawValue, color: Color(hex: "2A9D8F")) }
                }
            }
        }
    }
    
    private func tag(_ text: String, color: Color) -> some View {
        Text(text).font(.caption.weight(.medium)).padding(.horizontal, 10).padding(.vertical, 4).background(color.opacity(0.12)).foregroundStyle(color).clipShape(Capsule())
    }
    
    private var quickInfoBar: some View {
        HStack(spacing: 0) {
            infoItem("clock.fill", "Prep", "\(recipe.prepTimeMinutes)m")
            Divider().frame(height: 30)
            infoItem("flame.fill", "Cook", "\(recipe.cookTimeMinutes)m")
            Divider().frame(height: 30)
            infoItem("chart.bar.fill", "Level", recipe.difficulty.rawValue)
            Divider().frame(height: 30)
            infoItem("person.2.fill", "Serves", "\(recipe.servings)")
        }.padding(.vertical, 12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12)).shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
    
    private func infoItem(_ icon: String, _ label: String, _ value: String) -> some View {
        VStack(spacing: 4) { Image(systemName: icon).font(.caption).foregroundStyle(Color(hex: "2A9D8F")); Text(value).font(.subheadline.weight(.semibold)); Text(label).font(.caption2).foregroundStyle(.secondary) }.frame(maxWidth: .infinity)
    }
    
    private var ratingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Rating").font(.subheadline.weight(.semibold))
                if recipe.timesCookedTotal > 0 { Text("Cooked \(recipe.timesCookedTotal) time\(recipe.timesCookedTotal == 1 ? "" : "s")").font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
            StarRatingView(rating: Binding(get: { recipe.rating }, set: { r in recipe.rating = r; if let v = r { store.rateRecipe(recipe, rating: v) } }), size: 28)
        }.padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.03), radius: 3, y: 1)
    }
    
    // MARK: - Nutrition & Cost
    
    private var nutritionCostRow: some View {
        let nutrition = NutritionDatabase.estimate(for: recipe)
        let ps = nutrition.perServing
        let cost = recipe.estimatedCost
        
        return VStack(spacing: 8) {
            HStack(spacing: 12) {
                nutritionBadge("🔥", "\(ps.calories)", "cal")
                nutritionBadge("🥩", "\(ps.protein)g", "protein")
                nutritionBadge("🍞", "\(ps.carbs)g", "carbs")
                nutritionBadge("🧈", "\(ps.fat)g", "fat")
            }
            
            if cost > 0 {
                HStack {
                    Label("Est. Cost", systemImage: "dollarsign.circle").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", cost)) total")
                        .font(.caption.weight(.medium))
                    Text("• $\(String(format: "%.2f", recipe.costPerServing))/serving")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
    }
    
    private func nutritionBadge(_ emoji: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(emoji).font(.caption)
            Text(value).font(.subheadline.weight(.bold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }
    
    // MARK: - Serving Adjuster with Presets
    
    private var servingAdjuster: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Servings").font(.subheadline.weight(.semibold))
                Spacer()
                HStack(spacing: 12) {
                    Button { if adjustedServings > 1 { adjustedServings -= 1 } } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundStyle(Color(hex: "264653")) }
                    Text("\(adjustedServings)").font(.title3.weight(.bold)).frame(width: 30)
                    Button { adjustedServings += 1 } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Color(hex: "264653")) }
                }
            }
            // Presets
            HStack(spacing: 8) {
                scalePreset("Half", factor: 0.5)
                scalePreset("Original", factor: 1.0)
                scalePreset("Double", factor: 2.0)
                scalePreset("5x Prep", factor: 5.0)
            }
        }.padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func scalePreset(_ label: String, factor: Double) -> some View {
        let target = max(1, Int(Double(recipe.servings) * factor))
        let isActive = adjustedServings == target
        return Button { adjustedServings = target } label: {
            Text(label).font(.caption2.weight(.medium))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(isActive ? Color(hex: "2A9D8F").opacity(0.15) : Color(hex: "F8F6F0"))
                .foregroundStyle(isActive ? Color(hex: "2A9D8F") : .secondary)
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Ingredients with Pantry Check
    
    private var ingredientsSection: some View {
        let scaled = store.scaledIngredients(for: recipe, targetServings: adjustedServings)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients").font(.title3.weight(.bold))
            VStack(spacing: 0) {
                ForEach(Array(scaled.enumerated()), id: \.element.id) { idx, ing in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            let inPantry = store.isInPantry(ing.name)
                            Image(systemName: inPantry ? "checkmark.circle.fill" : "circle.fill")
                                .font(.caption2).foregroundStyle(inPantry ? .green : Color(hex: "2A9D8F"))
                            Text(ing.displayText).font(.body)
                                .foregroundStyle(inPantry ? .secondary : .primary)
                            Spacer()
                            if inPantry { Text("In pantry").font(.caption2).foregroundStyle(.green) }
                        }
                        if let sub = ing.substitution, !sub.isEmpty {
                            HStack(spacing: 4) { Image(systemName: "arrow.triangle.swap").font(.caption2); Text("Sub: \(sub)").font(.caption) }
                            .foregroundStyle(Color(hex: "BC6C25")).padding(.leading, 14)
                        }
                        if let price = ing.priceEstimate, price > 0 {
                            Text("~$\(String(format: "%.2f", price))").font(.caption2).foregroundStyle(.tertiary).padding(.leading, 14)
                        }
                    }.padding(.vertical, 10).padding(.horizontal, 12)
                    if idx < scaled.count - 1 { Divider().padding(.leading, 24) }
                }
            }.background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12)).shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
    }
    
    private func stepsSection(title: String, steps: [PrepStep]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3.weight(.bold))
            VStack(spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { idx, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(idx + 1)").font(.caption.weight(.bold)).foregroundStyle(.white)
                            .frame(width: 24, height: 24).background(Circle().fill(Color(hex: "2A9D8F")))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.text).font(.body)
                            if let t = step.timerDisplay {
                                HStack(spacing: 4) { Image(systemName: "timer"); Text(t) }.font(.caption).foregroundStyle(Color(hex: "E76F51"))
                                    .padding(.horizontal, 8).padding(.vertical, 4).background(Color(hex: "E76F51").opacity(0.1)).clipShape(Capsule())
                            }
                        }
                        Spacer()
                    }.padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.03), radius: 3, y: 1)
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) { Image(systemName: "note.text"); Text("Personal Notes").font(.title3.weight(.bold)) }
            Text(recipe.notes).font(.body).foregroundStyle(.secondary).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: "FFF8E7")).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var seasonsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best Seasons").font(.subheadline.weight(.semibold))
            HStack(spacing: 8) {
                ForEach(recipe.seasons) { season in
                    HStack(spacing: 4) { Image(systemName: season.icon).font(.caption); Text(season.rawValue).font(.caption) }
                    .padding(.horizontal, 10).padding(.vertical, 4).background(Color(hex: "2A9D8F").opacity(0.1)).clipShape(Capsule())
                }
            }
        }
    }
    
    private var versionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Versions (\(recipe.versions.count))").font(.subheadline.weight(.semibold))
                Spacer()
                Button("Manage") { showVersions = true }.font(.caption.weight(.medium)).foregroundStyle(Color(hex: "2A9D8F"))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(recipe.versions) { v in
                        let isActive = recipe.activeVersionID == v.id
                        Button { store.loadVersion(v, into: recipe.id); refreshRecipe() } label: {
                            VStack(spacing: 4) {
                                Text(v.name).font(.caption.weight(.medium))
                                Text(v.dateCreated.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(isActive ? Color(hex: "2A9D8F").opacity(0.15) : Color.white)
                            .foregroundStyle(isActive ? Color(hex: "2A9D8F") : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isActive ? Color(hex: "2A9D8F") : Color.gray.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
            }
        }
    }
    
    private var cookingLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) { Image(systemName: "clock.arrow.circlepath"); Text("Cooking History").font(.title3.weight(.bold)) }
                Spacer()
                Button("See All") { showCookingLog = true }.font(.caption.weight(.medium)).foregroundStyle(Color(hex: "2A9D8F"))
            }
            VStack(spacing: 0) {
                ForEach(Array(recipe.cookingLog.sorted { $0.date > $1.date }.prefix(3).enumerated()), id: \.element.id) { idx, entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened)).font(.subheadline)
                            Text(Calendar.current.weekdaySymbols[max(0, entry.dayOfWeek - 1)]).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let r = entry.rating { StarRatingDisplay(rating: Double(r), size: 12) }
                    }.padding(.vertical, 8).padding(.horizontal, 12)
                    if idx < 2 { Divider().padding(.leading, 12) }
                }
            }.background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var cookButton: some View {
        Button { showCookingMode = true } label: {
            HStack { Image(systemName: "flame.fill"); Text("Start Cooking").fontWeight(.semibold) }
            .font(.title3).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(Color(hex: "E76F51")).clipShape(RoundedRectangle(cornerRadius: 14)).shadow(color: Color(hex: "E76F51").opacity(0.3), radius: 8, y: 4)
        }
    }
    
    // MARK: - Sheets
    
    private var collectionPickerSheet: some View {
        NavigationStack {
            List { ForEach(store.collections, id: \.self) { col in
                let isIn = recipe.collections.contains(col)
                Button { if isIn { store.removeRecipeFromCollection(recipe, collection: col); recipe.collections.removeAll { $0 == col } } else { store.addRecipeToCollection(recipe, collection: col); recipe.collections.append(col) } } label: { HStack { Text(col); Spacer(); if isIn { Image(systemName: "checkmark").foregroundStyle(Color(hex: "2A9D8F")) } } }.foregroundStyle(.primary)
            } }
            .navigationTitle("Collections").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showCollectionPicker = false } } }
        }.presentationDetents([.medium])
    }
    
    private var cookingLogSheet: some View {
        NavigationStack {
            List { ForEach(recipe.cookingLog.sorted(by: { $0.date > $1.date })) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) { Text(entry.date.formatted(date: .long, time: .shortened)).font(.body); Text(Calendar.current.weekdaySymbols[max(0, entry.dayOfWeek - 1)]).font(.caption).foregroundStyle(.secondary) }
                    Spacer()
                    if let r = entry.rating { StarRatingDisplay(rating: Double(r)) } else { Text("No rating").font(.caption).foregroundStyle(.tertiary) }
                }
            } }
            .navigationTitle("Cooking History").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showCookingLog = false } } }
        }.presentationDetents([.medium, .large])
    }
    
    private var versionsSheet: some View {
        NavigationStack {
            List { ForEach(recipe.versions) { v in
                HStack {
                    VStack(alignment: .leading) { Text(v.name).font(.body.weight(.medium)); Text("\(v.ingredients.count) ingredients • \(v.cookingSteps.count) steps").font(.caption).foregroundStyle(.secondary) }
                    Spacer()
                    if recipe.activeVersionID == v.id { Text("Active").font(.caption).foregroundStyle(Color(hex: "2A9D8F")) }
                    Button { store.loadVersion(v, into: recipe.id); refreshRecipe(); showVersions = false } label: { Text("Load").font(.caption.weight(.medium)) }
                }
            } }
            .navigationTitle("Recipe Versions").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showVersions = false } } }
        }.presentationDetents([.medium])
    }
}
