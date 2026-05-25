import SwiftUI
import PhotosUI

struct AddRecipeView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss
    var existingRecipe: Recipe?
    private var isEditing: Bool { existingRecipe != nil && existingRecipe?.title.isEmpty == false }
    @State private var recipe: Recipe
    @State private var currentStep: EntryStep = .category
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var ingQuantity = ""
    @State private var ingUnit = ""
    @State private var ingName = ""
    @State private var ingSubstitution = ""
    @State private var ingPrice = ""
    @State private var prepStepText = ""
    @State private var prepStepTimer = ""
    @State private var cookStepText = ""
    @State private var cookStepTimer = ""
    @State private var showSavedScreen = false
    @State private var savedRecipeTitle = ""
    
    init(existingRecipe: Recipe? = nil) { self.existingRecipe = existingRecipe; _recipe = State(initialValue: existingRecipe ?? Recipe.blank()) }
    
    enum EntryStep: Int, CaseIterable {
        case category = 0, subCategory, details, seasons, ingredients, preparation, cookingSteps, review
        var title: String {
            switch self {
            case .category: return "Category"; case .subCategory: return "Sub-Category"; case .details: return "Details"
            case .seasons: return "Seasons"; case .ingredients: return "Ingredients"; case .preparation: return "Preparation"
            case .cookingSteps: return "Cooking Steps"; case .review: return "Review & Save"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F6F0").ignoresSafeArea()
                
                if showSavedScreen {
                    RecipeSavedView(
                        recipeTitle: savedRecipeTitle,
                        onDone: {
                            dismiss()
                        },
                        onAddMore: {
                            // Reset everything for a new recipe
                            recipe = Recipe.blank()
                            currentStep = .category
                            ingQuantity = ""; ingUnit = ""; ingName = ""; ingSubstitution = ""; ingPrice = ""
                            prepStepText = ""; prepStepTimer = ""; cookStepText = ""; cookStepTimer = ""
                            selectedPhotoItem = nil
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSavedScreen = false
                            }
                        }
                    )
                    .transition(.opacity)
                } else {
                    VStack(spacing: 0) {
                        progressBar
                        TabView(selection: $currentStep) {
                            categorySelection.tag(EntryStep.category)
                            subCategorySelection.tag(EntryStep.subCategory)
                            detailsEntry.tag(EntryStep.details)
                            seasonsEntry.tag(EntryStep.seasons)
                            ingredientsEntry.tag(EntryStep.ingredients)
                            preparationEntry.tag(EntryStep.preparation)
                            cookingStepsEntry.tag(EntryStep.cookingSteps)
                            reviewScreen.tag(EntryStep.review)
                        }.tabViewStyle(.page(indexDisplayMode: .never)).animation(.easeInOut(duration: 0.3), value: currentStep)
                        bottomNavBar
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSavedScreen)
            .navigationTitle(showSavedScreen ? "" : (isEditing ? "Edit Recipe" : currentStep.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !showSavedScreen {
                        Button("Cancel") { dismiss() }.foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var progressBar: some View {
        let total = EntryStep.allCases.count; let current = currentStep.rawValue + 1
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: "E0DDD5")).frame(height: 4)
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: "2A9D8F")).frame(width: geo.size.width * CGFloat(current) / CGFloat(total), height: 4).animation(.easeInOut, value: currentStep)
            }
        }.frame(height: 4).padding(.horizontal).padding(.top, 8)
    }
    
    private var bottomNavBar: some View {
        HStack {
            if currentStep.rawValue > 0 {
                Button { withAnimation { currentStep = EntryStep(rawValue: currentStep.rawValue - 1) ?? .category } } label: {
                    HStack(spacing: 4) { Image(systemName: "chevron.left"); Text("Back") }.font(.body.weight(.medium)).foregroundStyle(Color(hex: "264653"))
                }
            }
            Spacer()
            if currentStep == .review {
                Button {
                    // Auto-suggest difficulty before saving
                    let allTexts = (recipe.preparationSteps + recipe.cookingSteps).map { $0.text }
                    let suggested = DifficultyEstimator.suggest(ingredientCount: recipe.ingredients.count, prepStepCount: recipe.preparationSteps.count, cookStepCount: recipe.cookingSteps.count, totalTimeMinutes: recipe.totalTimeMinutes, stepTexts: allTexts)
                    if !isEditing { recipe.difficulty = suggested }
                    
                    // Save the recipe
                    if isEditing {
                        store.updateRecipe(recipe)
                        dismiss()
                    } else {
                        store.addRecipe(recipe)
                        savedRecipeTitle = recipe.title.isEmpty ? "Untitled Recipe" : recipe.title
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSavedScreen = true
                        }
                    }
                } label: {
                    Text(isEditing ? "Save Changes" : "Save Recipe").font(.body.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 10).background(Color(hex: "2A9D8F")).clipShape(Capsule())
                }.disabled(recipe.title.isEmpty)
            } else {
                Button { withAnimation { currentStep = EntryStep(rawValue: currentStep.rawValue + 1) ?? .review } } label: {
                    HStack(spacing: 4) { Text("Next"); Image(systemName: "chevron.right") }.font(.body.weight(.medium)).foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 10).background(Color(hex: "2A9D8F")).clipShape(Capsule())
                }
            }
        }.padding(.horizontal, 20).padding(.vertical, 12).background(Color.white.shadow(color: .black.opacity(0.05), radius: 8, y: -2))
    }
    
    // MARK: - Category
    private var categorySelection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What type of meal is this?").font(.title3.weight(.semibold)).padding(.horizontal)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(RecipeCategory.allCases) { cat in
                        Button { recipe.category = cat } label: {
                            VStack(spacing: 8) { Image(systemName: cat.icon).font(.title2); Text(cat.rawValue).font(.subheadline.weight(.medium)) }
                            .frame(maxWidth: .infinity).padding(.vertical, 20)
                            .background(recipe.category == cat ? cat.color.opacity(0.15) : Color.white)
                            .foregroundStyle(recipe.category == cat ? cat.color : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(recipe.category == cat ? cat.color : Color.clear, lineWidth: 2))
                            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                        }
                    }
                }.padding(.horizontal)
            }.padding(.top, 20)
        }
    }
    
    // MARK: - Sub-Category
    private var subCategorySelection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select one or more sub-categories").font(.title3.weight(.semibold)).padding(.horizontal)
                FlowLayout(spacing: 8) {
                    ForEach(RecipeSubCategory.allCases) { sub in
                        let sel = recipe.subCategories.contains(sub)
                        Button { if sel { recipe.subCategories.removeAll { $0 == sub } } else { recipe.subCategories.append(sub) } } label: {
                            HStack(spacing: 4) { Image(systemName: sub.icon).font(.caption); Text(sub.rawValue).font(.subheadline) }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(sel ? Color(hex: "2A9D8F").opacity(0.15) : Color.white)
                            .foregroundStyle(sel ? Color(hex: "2A9D8F") : .primary)
                            .clipShape(Capsule()).overlay(Capsule().stroke(sel ? Color(hex: "2A9D8F") : Color.gray.opacity(0.2), lineWidth: 1))
                        }
                    }
                }.padding(.horizontal)
            }.padding(.top, 20)
        }
    }
    
    // MARK: - Details
    private var detailsEntry: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                field("Recipe Title") { TextField("e.g. Grandma's Chicken Pot Pie", text: $recipe.title).textFieldStyle(.plain).padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.04), radius: 3, y: 1) }
                field("Short Description") { TextField("A brief description...", text: $recipe.description, axis: .vertical).textFieldStyle(.plain).lineLimit(3...6).padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.04), radius: 3, y: 1) }
                field("Hero Photo (optional)") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let d = recipe.imageData, let img = UIImage(data: d) { Image(uiImage: img).resizable().scaledToFill().frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 12)) }
                        else { VStack(spacing: 8) { Image(systemName: "camera.fill").font(.title2); Text("Tap to add a photo").font(.subheadline) }.foregroundStyle(.secondary).frame(maxWidth: .infinity).frame(height: 120).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6]))) }
                    }.onChange(of: selectedPhotoItem) { _, n in Task { if let d = try? await n?.loadTransferable(type: Data.self) { recipe.imageData = d } } }
                }
                HStack(spacing: 12) { numField("Prep (min)", value: $recipe.prepTimeMinutes); numField("Cook (min)", value: $recipe.cookTimeMinutes); numField("Servings", value: $recipe.servings) }
                field("Difficulty") {
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            ForEach(RecipeDifficulty.allCases) { d in
                                Button { recipe.difficulty = d } label: {
                                    Text(d.rawValue).font(.subheadline.weight(.medium)).frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(recipe.difficulty == d ? d.color.opacity(0.15) : Color.white)
                                    .foregroundStyle(recipe.difficulty == d ? d.color : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(recipe.difficulty == d ? d.color : Color.gray.opacity(0.2), lineWidth: 1))
                                }
                            }
                        }
                        Text("Difficulty will be auto-suggested on save based on complexity").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }.padding(.horizontal).padding(.top, 20)
        }
    }
    
    private func field(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) { Text(label).font(.subheadline.weight(.semibold)); content() }
    }
    
    private func numField(_ label: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption.weight(.semibold))
            TextField("0", value: value, format: .number).keyboardType(.numberPad).textFieldStyle(.plain).multilineTextAlignment(.center)
                .padding(10).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.04), radius: 3, y: 1)
        }
    }
    
    // MARK: - Seasons
    private var seasonsEntry: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("When is this recipe best?").font(.title3.weight(.semibold)).padding(.horizontal)
                Text("Select the seasons this recipe is best for, or choose All Year.").font(.caption).foregroundStyle(.secondary).padding(.horizontal)
                
                VStack(spacing: 10) {
                    ForEach(RecipeSeason.allCases) { season in
                        let sel = recipe.seasons.contains(season)
                        Button {
                            if season == .allYear {
                                recipe.seasons = [.allYear]
                            } else {
                                recipe.seasons.removeAll { $0 == .allYear }
                                if sel { recipe.seasons.removeAll { $0 == season } }
                                else { recipe.seasons.append(season) }
                                if recipe.seasons.isEmpty { recipe.seasons = [.allYear] }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: season.icon).font(.title3).frame(width: 30)
                                Text(season.rawValue).font(.body.weight(.medium))
                                Spacer()
                                if sel { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(hex: "2A9D8F")) }
                            }
                            .padding(14).background(sel ? Color(hex: "2A9D8F").opacity(0.08) : Color.white)
                            .foregroundStyle(sel ? Color(hex: "2A9D8F") : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(sel ? Color(hex: "2A9D8F") : Color.gray.opacity(0.15), lineWidth: 1))
                        }
                    }
                }.padding(.horizontal)
            }.padding(.top, 20)
        }
    }
    
    // MARK: - Ingredients
    private var ingredientsEntry: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add your ingredients").font(.title3.weight(.semibold)).padding(.horizontal)
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        TextField("Qty", text: $ingQuantity).textFieldStyle(.plain).frame(width: 55).padding(10).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 8))
                        TextField("Unit", text: $ingUnit).textFieldStyle(.plain).frame(width: 55).padding(10).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 8))
                        TextField("Ingredient", text: $ingName).textFieldStyle(.plain).padding(10).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.swap").font(.caption).foregroundStyle(Color(hex: "BC6C25"))
                            TextField("Substitution (optional)", text: $ingSubstitution).textFieldStyle(.plain).font(.subheadline)
                        }.padding(8).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 8))
                        HStack(spacing: 4) {
                            Text("$").font(.caption).foregroundStyle(.secondary)
                            TextField("Price", text: $ingPrice).textFieldStyle(.plain).keyboardType(.decimalPad).font(.subheadline).frame(width: 50)
                        }.padding(8).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Text("Qty supports fractions: 1/4, 1 1/2, etc.").font(.caption2).foregroundStyle(.secondary)
                    Button {
                        guard !ingName.isEmpty else { return }
                        let price = Double(ingPrice)
                        recipe.ingredients.append(Ingredient(quantity: ingQuantity, unit: ingUnit, name: ingName, substitution: ingSubstitution.isEmpty ? nil : ingSubstitution, priceEstimate: price))
                        ingQuantity = ""; ingUnit = ""; ingName = ""; ingSubstitution = ""; ingPrice = ""
                    } label: {
                        HStack { Image(systemName: "plus.circle.fill"); Text("Add Ingredient") }.font(.subheadline.weight(.medium)).foregroundStyle(Color(hex: "2A9D8F")).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(hex: "2A9D8F").opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }.padding(.horizontal)
                VStack(spacing: 6) {
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.element.id) { idx, ing in
                        HStack(alignment: .top) {
                            Text("\(idx + 1).").font(.caption).foregroundStyle(.secondary).frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ing.displayText).font(.body)
                                if let sub = ing.substitution, !sub.isEmpty { HStack(spacing: 4) { Image(systemName: "arrow.triangle.swap").font(.caption2); Text(sub).font(.caption) }.foregroundStyle(Color(hex: "BC6C25")) }
                                if let p = ing.priceEstimate, p > 0 { Text("$\(String(format: "%.2f", p))").font(.caption2).foregroundStyle(.tertiary) }
                            }
                            Spacer()
                            Button { recipe.ingredients.removeAll { $0.id == ing.id } } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.red.opacity(0.6)) }
                        }.padding(.horizontal).padding(.vertical, 8).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }.padding(.horizontal)
            }.padding(.top, 20)
        }
    }
    
    // MARK: - Steps
    private var preparationEntry: some View { stepsEntry(title: "Preparation Steps", subtitle: "Chopping, marinating, preheating — before cooking.", steps: $recipe.preparationSteps, inputText: $prepStepText, timerInput: $prepStepTimer) }
    private var cookingStepsEntry: some View { stepsEntry(title: "Cooking Steps", subtitle: "The step-by-step cooking process.", steps: $recipe.cookingSteps, inputText: $cookStepText, timerInput: $cookStepTimer) }
    
    private func stepsEntry(title: String, subtitle: String, steps: Binding<[PrepStep]>, inputText: Binding<String>, timerInput: Binding<String>) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(.title3.weight(.semibold)).padding(.horizontal)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).padding(.horizontal)
                VStack(spacing: 10) {
                    TextField("Describe this step...", text: inputText, axis: .vertical).textFieldStyle(.plain).lineLimit(2...4).padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10))
                    HStack {
                        Text("Timer (seconds, optional):").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. 300", text: timerInput).keyboardType(.numberPad).textFieldStyle(.plain).frame(width: 80).padding(8).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Button {
                        guard !inputText.wrappedValue.isEmpty else { return }
                        steps.wrappedValue.append(PrepStep(text: inputText.wrappedValue, timerSeconds: Int(timerInput.wrappedValue)))
                        inputText.wrappedValue = ""; timerInput.wrappedValue = ""
                    } label: {
                        HStack { Image(systemName: "plus.circle.fill"); Text("Add Step") }.font(.subheadline.weight(.medium)).foregroundStyle(Color(hex: "2A9D8F")).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(hex: "2A9D8F").opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }.padding(.horizontal)
                VStack(spacing: 6) {
                    ForEach(Array(steps.wrappedValue.enumerated()), id: \.element.id) { idx, step in
                        HStack(alignment: .top) {
                            Text("\(idx + 1).").font(.subheadline.weight(.bold)).foregroundStyle(Color(hex: "2A9D8F")).frame(width: 28, alignment: .leading)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.text).font(.body)
                                if let t = step.timerDisplay { HStack(spacing: 4) { Image(systemName: "timer"); Text(t) }.font(.caption).foregroundStyle(Color(hex: "E76F51")) }
                            }
                            Spacer()
                            Button { steps.wrappedValue.removeAll { $0.id == step.id } } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.red.opacity(0.6)) }
                        }.padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }.padding(.horizontal)
            }.padding(.top, 20)
        }
    }
    
    // MARK: - Review
    private var reviewScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title.isEmpty ? "Untitled Recipe" : recipe.title).font(.title2.weight(.bold))
                    HStack(spacing: 12) {
                        Label(recipe.category.rawValue, systemImage: recipe.category.icon).font(.caption).foregroundStyle(recipe.category.color)
                        Label(recipe.totalTimeDisplay, systemImage: "clock.fill").font(.caption).foregroundStyle(.secondary)
                        Label("\(recipe.servings) servings", systemImage: "person.2.fill").font(.caption).foregroundStyle(.secondary)
                    }
                    if !recipe.seasons.isEmpty {
                        HStack(spacing: 4) { ForEach(recipe.seasons) { s in Text(s.rawValue).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(Color(hex: "2A9D8F").opacity(0.1)).clipShape(Capsule()) } }
                    }
                }.padding(.horizontal)
                if !recipe.description.isEmpty { Text(recipe.description).font(.body).foregroundStyle(.secondary).padding(.horizontal) }
                Divider().padding(.horizontal)
                if !recipe.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients (\(recipe.ingredients.count))").font(.headline)
                        ForEach(recipe.ingredients) { i in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("• \(i.displayText)").font(.body)
                                if let s = i.substitution, !s.isEmpty { Text("  ↔ \(s)").font(.caption).foregroundStyle(Color(hex: "BC6C25")) }
                            }
                        }
                        let cost = recipe.estimatedCost
                        if cost > 0 { Text("Estimated total: $\(String(format: "%.2f", cost))").font(.caption).foregroundStyle(.secondary) }
                    }.padding(.horizontal)
                }
                if !recipe.preparationSteps.isEmpty { VStack(alignment: .leading, spacing: 8) { Text("Preparation (\(recipe.preparationSteps.count) steps)").font(.headline); ForEach(Array(recipe.preparationSteps.enumerated()), id: \.element.id) { i, s in Text("\(i+1). \(s.text)").font(.body) } }.padding(.horizontal) }
                if !recipe.cookingSteps.isEmpty { VStack(alignment: .leading, spacing: 8) { Text("Cooking Steps (\(recipe.cookingSteps.count) steps)").font(.headline); ForEach(Array(recipe.cookingSteps.enumerated()), id: \.element.id) { i, s in Text("\(i+1). \(s.text)").font(.body) } }.padding(.horizontal) }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Personal Notes (optional)").font(.subheadline.weight(.semibold))
                    TextField("Tips, tweaks, reminders...", text: $recipe.notes, axis: .vertical).textFieldStyle(.plain).lineLimit(2...5).padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                }.padding(.horizontal)
            }.padding(.top, 20).padding(.bottom, 40)
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize { arrange(proposal: proposal, subviews: subviews).size }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let r = arrange(proposal: proposal, subviews: subviews)
        for (i, p) in r.positions.enumerated() { subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified) }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let mw = proposal.width ?? .infinity; var pos: [CGPoint] = []; var x: CGFloat = 0; var y: CGFloat = 0; var rh: CGFloat = 0
        for sv in subviews { let s = sv.sizeThatFits(.unspecified); if x + s.width > mw, x > 0 { x = 0; y += rh + spacing; rh = 0 }; pos.append(CGPoint(x: x, y: y)); rh = max(rh, s.height); x += s.width + spacing }
        return (pos, CGSize(width: mw, height: y + rh))
    }
}
