import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var showRecipePicker = false
    @State private var selectedRecipeIDs: Set<UUID> = []
    
    var body: some View {
        ZStack {
            Color(hex: "F8F6F0").ignoresSafeArea()
            if store.groceryList.isEmpty { emptyState } else { groceryContent }
        }
        .navigationTitle("Grocery List")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showRecipePicker = true } label: { Label("Add Recipes", systemImage: "plus") }
                    if !store.groceryList.isEmpty { Button(role: .destructive) { store.clearGroceryList() } label: { Label("Clear List", systemImage: "trash") } }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showRecipePicker) { recipePickerSheet }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "cart.fill").font(.system(size: 56)).foregroundStyle(Color(hex: "2A9D8F").opacity(0.4))
            Text("No grocery list yet").font(.title3.weight(.semibold))
            Text("Select recipes to generate a combined shopping list organized by aisle.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 40)
            Button { showRecipePicker = true } label: {
                HStack(spacing: 6) { Image(systemName: "plus.circle.fill"); Text("Choose Recipes") }
                .font(.body.weight(.semibold)).foregroundStyle(.white).padding(.horizontal, 24).padding(.vertical, 12)
                .background(Color(hex: "2A9D8F")).clipShape(Capsule())
            }.padding(.top, 8)
            Spacer()
        }
    }
    
    private var groceryContent: some View {
        let grouped = Dictionary(grouping: store.groceryList) { $0.aisle }
        let sortedAisles = grouped.keys.sorted { $0.rawValue < $1.rawValue }
        let checkedCount = store.groceryList.filter { $0.isChecked }.count
        let totalCount = store.groceryList.count
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Progress
                VStack(spacing: 6) {
                    HStack {
                        Text("\(checkedCount) of \(totalCount) items").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                        Spacer()
                        if checkedCount == totalCount && totalCount > 0 { Text("All done!").font(.subheadline.weight(.semibold)).foregroundStyle(Color(hex: "2A9D8F")) }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color(hex: "E0DDD5")).frame(height: 6)
                            RoundedRectangle(cornerRadius: 3).fill(Color(hex: "2A9D8F"))
                                .frame(width: totalCount > 0 ? geo.size.width * CGFloat(checkedCount) / CGFloat(totalCount) : 0, height: 6)
                                .animation(.easeInOut, value: checkedCount)
                        }
                    }.frame(height: 6)
                }.padding(.horizontal)
                
                ForEach(sortedAisles, id: \.self) { aisle in
                    if let items = grouped[aisle] {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: aisle.icon).font(.caption).foregroundStyle(Color(hex: "2A9D8F"))
                                Text(aisle.rawValue).font(.subheadline.weight(.bold)).foregroundStyle(Color(hex: "264653"))
                            }.padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                                    Button { store.toggleGroceryItem(item) } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(item.isChecked ? Color(hex: "2A9D8F") : .secondary).font(.title3)
                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack(spacing: 6) {
                                                    Text(item.name).font(.body).strikethrough(item.isChecked)
                                                        .foregroundStyle(item.isChecked ? .secondary : .primary)
                                                    if item.inPantry { Text("IN PANTRY").font(.system(size: 8, weight: .bold)).foregroundStyle(.green).padding(.horizontal, 4).padding(.vertical, 2).background(Color.green.opacity(0.1)).clipShape(Capsule()) }
                                                }
                                                if !item.quantities.isEmpty { Text(item.quantities.joined(separator: " + ")).font(.caption).foregroundStyle(.secondary) }
                                            }
                                            Spacer()
                                        }.padding(.vertical, 10).padding(.horizontal, 12)
                                    }.buttonStyle(.plain)
                                    if idx < items.count - 1 { Divider().padding(.leading, 48) }
                                }
                            }.background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12)).shadow(color: .black.opacity(0.04), radius: 4, y: 2).padding(.horizontal)
                        }
                    }
                }
            }.padding(.top, 12).padding(.bottom, 20)
        }
    }
    
    private var recipePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(store.recipes) { recipe in
                    let sel = selectedRecipeIDs.contains(recipe.id)
                    Button { if sel { selectedRecipeIDs.remove(recipe.id) } else { selectedRecipeIDs.insert(recipe.id) } } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) { Text(recipe.title).font(.body); Text("\(recipe.ingredients.count) ingredients").font(.caption).foregroundStyle(.secondary) }
                            Spacer()
                            if sel { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(hex: "2A9D8F")) }
                        }
                    }.foregroundStyle(.primary)
                }
            }
            .navigationTitle("Select Recipes").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { showRecipePicker = false } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Generate") { store.generateGroceryList(for: store.recipes.filter { selectedRecipeIDs.contains($0.id) }); showRecipePicker = false }
                    .fontWeight(.semibold).disabled(selectedRecipeIDs.isEmpty)
                }
            }
        }
    }
}
