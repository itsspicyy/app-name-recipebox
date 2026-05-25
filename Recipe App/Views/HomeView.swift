import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var showingAddSheet = false
    @State private var showingImportSheet = false
    @State private var showingAddOptions = false
    @State private var showingTextImport = false
    @State private var showingURLImport = false
    @State private var selectedTab: HomeTab = .all
    
    // Side menu & settings
    @State private var isMenuOpen = false
    @State private var showSettings = false
    
    enum HomeTab: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case collections = "Collections"
        case groceries = "Groceries"
        case pantry = "Pantry"
        case mealPlan = "Plan"
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    Color(hex: "F8F6F0").ignoresSafeArea()
                    VStack(spacing: 0) {
                        tabBar
                        switch selectedTab {
                        case .all:         allTabContent
                        case .favorites:   recipeList(recipes: store.favoriteRecipes, emptyIcon: "heart.slash", emptyTitle: "No favorites yet", emptySub: "Tap the heart on any recipe to save it here.")
                        case .collections: collectionsView
                        case .groceries:   GroceryListView()
                        case .pantry:      PantryView()
                        case .mealPlan:    MealPlanView()
                        }
                    }
                }
                .navigationTitle("Recipe Box")
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $store.searchText, prompt: "Search recipes or ingredients...")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        HamburgerButton(isMenuOpen: $isMenuOpen)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showingAddOptions = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(Color(hex: "2A9D8F"))
                        }
                    }
                }
                .confirmationDialog("Add a Recipe", isPresented: $showingAddOptions) {
                    Button("Type it manually") { showingAddSheet = true }
                    Button("Upload from Camera Roll") { showingImportSheet = true }
                    Button("Scan with Camera") { showingImportSheet = true }
                    Button("Paste from Text") { showingTextImport = true }
                    Button("Import from URL") { showingURLImport = true }
                    Button("Cancel", role: .cancel) {}
                } message: { Text("How would you like to add your recipe?") }
                .sheet(isPresented: $showingAddSheet) { AddRecipeView() }
                .sheet(isPresented: $showingImportSheet) { ImageImportView() }
                .sheet(isPresented: $showingTextImport) { TextImportView() }
                .sheet(isPresented: $showingURLImport) { URLImportView() }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(store)
                }
            }
            
            // Side menu overlays everything
            SideMenuView(
                isOpen: $isMenuOpen,
                showSettings: $showSettings,
                selectedTab: $selectedTab
            )
            .environmentObject(store)
        }
    }
    
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(HomeTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                    } label: {
                        HStack(spacing: 4) {
                            if let icon = tabIcon(tab) { Image(systemName: icon).font(.caption2) }
                            Text(tab.rawValue).font(.subheadline).fontWeight(selectedTab == tab ? .semibold : .regular)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(selectedTab == tab ? Color(hex: "2A9D8F").opacity(0.15) : Color.clear)
                        .foregroundStyle(selectedTab == tab ? Color(hex: "2A9D8F") : .secondary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
    }
    
    private func tabIcon(_ tab: HomeTab) -> String? {
        switch tab {
        case .groceries: return "cart.fill"
        case .pantry: return "refrigerator.fill"
        case .mealPlan: return "calendar"
        default: return nil
        }
    }
    
    private var allTabContent: some View {
        VStack(spacing: 0) {
            categoryChips
            if store.recipes.isEmpty {
                EmptyStateView(icon: "book.closed.fill", title: "Your recipe box is empty", subtitle: "Tap the + button to add your first recipe.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if AppSettings.shared.showMealSuggestions, let suggestion = store.topSuggestion {
                            suggestionCard(suggestion).padding(.bottom, 4)
                        }
                        let list = store.filteredRecipes
                        if list.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass").font(.title).foregroundStyle(.secondary)
                                Text("No recipes match").font(.subheadline).foregroundStyle(.secondary)
                            }.padding(.top, 40)
                        } else {
                            ForEach(list) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) { RecipeCardView(recipe: recipe) }.buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 20)
                }
            }
        }
    }
    
    private func suggestionCard(_ s: MealSuggestionEngine.ScoredRecipe) -> some View {
        NavigationLink(destination: RecipeDetailView(recipe: s.recipe)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles").font(.caption).foregroundStyle(Color(hex: "F4A261"))
                    Text("Suggested for You").font(.caption.weight(.bold)).foregroundStyle(Color(hex: "F4A261")).textCase(.uppercase).tracking(1)
                    Spacer()
                    Text(s.reason).font(.caption2).foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    Group {
                        if let d = s.recipe.imageData, let img = UIImage(data: d) {
                            Image(uiImage: img).resizable().scaledToFill()
                        } else {
                            ZStack { s.recipe.category.color.opacity(0.2); Image(systemName: s.recipe.category.icon).font(.title3).foregroundStyle(s.recipe.category.color.opacity(0.6)) }
                        }
                    }.frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(s.recipe.title).font(.headline).foregroundStyle(.primary).lineLimit(1)
                        HStack(spacing: 8) {
                            Label(s.recipe.category.rawValue, systemImage: s.recipe.category.icon).font(.caption2).foregroundStyle(s.recipe.category.color)
                            Label(s.recipe.totalTimeDisplay, systemImage: "clock").font(.caption2).foregroundStyle(.secondary)
                            if let avg = s.recipe.averageRating { StarRatingDisplay(rating: avg, size: 10) }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(14)
            .background(LinearGradient(colors: [Color(hex: "FFF8E7"), .white], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "F4A261").opacity(0.15), radius: 8, y: 3)
        }.buttonStyle(.plain)
    }
    
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipBtn(label: "All", icon: "square.grid.2x2.fill", sel: store.selectedCategory == nil) { store.selectedCategory = nil; store.selectedSubCategory = nil }
                ForEach(RecipeCategory.allCases) { cat in
                    chipBtn(label: cat.rawValue, icon: cat.icon, sel: store.selectedCategory == cat) {
                        store.selectedCategory = store.selectedCategory == cat ? nil : cat; store.selectedSubCategory = nil
                    }
                }
            }.padding(.horizontal)
        }.padding(.bottom, 8)
    }
    
    private func chipBtn(label: String, icon: String, sel: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) { Image(systemName: icon).font(.caption); Text(label).font(.caption).fontWeight(.medium) }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(sel ? Color(hex: "264653") : Color.white)
            .foregroundStyle(sel ? .white : Color(hex: "264653"))
            .clipShape(Capsule()).shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }
    
    private func recipeList(recipes: [Recipe], emptyIcon: String, emptyTitle: String, emptySub: String) -> some View {
        Group {
            if recipes.isEmpty { EmptyStateView(icon: emptyIcon, title: emptyTitle, subtitle: emptySub) }
            else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(recipes) { r in NavigationLink(destination: RecipeDetailView(recipe: r)) { RecipeCardView(recipe: r) }.buttonStyle(.plain) }
                    }.padding(.horizontal).padding(.bottom, 20)
                }
            }
        }
    }
    
    @State private var newCollectionName = ""
    @State private var showNewCollection = false
    
    private var collectionsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Button { showNewCollection = true } label: {
                    HStack { Image(systemName: "plus.circle.fill"); Text("New Collection").fontWeight(.medium) }
                    .foregroundStyle(Color(hex: "2A9D8F")).frame(maxWidth: .infinity, alignment: .leading).padding()
                    .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12)).shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                }
                .alert("New Collection", isPresented: $showNewCollection) {
                    TextField("Collection name", text: $newCollectionName)
                    Button("Add") { store.addCollection(newCollectionName); newCollectionName = "" }
                    Button("Cancel", role: .cancel) { newCollectionName = "" }
                }
                ForEach(store.collections, id: \.self) { col in
                    NavigationLink(destination: CollectionDetailView(collectionName: col)) {
                        HStack {
                            Image(systemName: "folder.fill").foregroundStyle(Color(hex: "E76F51")).font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(col).font(.headline).foregroundStyle(.primary)
                                Text("\(store.recipesInCollection(col).count) recipes").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }.padding().background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12)).shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal).padding(.bottom, 20)
        }
    }
}

struct CollectionDetailView: View {
    @EnvironmentObject var store: RecipeStore
    let collectionName: String
    var body: some View {
        let recipes = store.recipesInCollection(collectionName)
        Group {
            if recipes.isEmpty { EmptyStateView(icon: "folder", title: "Empty collection", subtitle: "Add recipes from the recipe detail screen.") }
            else { ScrollView { LazyVStack(spacing: 12) { ForEach(recipes) { r in NavigationLink(destination: RecipeDetailView(recipe: r)) { RecipeCardView(recipe: r) }.buttonStyle(.plain) } }.padding(.horizontal) } }
        }.navigationTitle(collectionName).background(Color(hex: "F8F6F0"))
    }
}
