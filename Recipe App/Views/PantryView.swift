import SwiftUI

struct PantryView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var newItem = ""
    @State private var searchText = ""
    
    var filteredItems: [PantryItem] {
        if searchText.isEmpty { return store.pantryItems.sorted { $0.name < $1.name } }
        return store.pantryItems.filter { $0.name.lowercased().contains(searchText.lowercased()) }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F8F6F0").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Add item bar
                HStack(spacing: 8) {
                    TextField("Add ingredient to pantry...", text: $newItem)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button {
                        store.addPantryItem(newItem)
                        newItem = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color(hex: "2A9D8F"))
                    }
                    .disabled(newItem.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                if store.pantryItems.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "refrigerator.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(hex: "2A9D8F").opacity(0.4))
                        Text("Your pantry is empty")
                            .font(.title3.weight(.semibold))
                        Text("Add ingredients you have on hand. When viewing recipes, items you already have will be marked.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: "2A9D8F"))
                                    .font(.body)
                                Text(item.name)
                                    .font(.body)
                                Spacer()
                                Text(item.dateAdded.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .onDelete { offsets in
                            let items = filteredItems
                            for i in offsets {
                                store.removePantryItem(items[i])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search pantry...")
                }
            }
        }
        .navigationTitle("My Pantry")
    }
}
