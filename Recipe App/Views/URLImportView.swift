import SwiftUI

struct URLImportView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss
    @State private var urlText = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showEditor = false
    @State private var prefilledRecipe: Recipe? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F6F0").ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color(hex: "2A9D8F").opacity(0.5))
                    
                    Text("Import from URL")
                        .font(.title2.weight(.bold))
                    
                    Text("Paste a link to a recipe page. Most recipe websites include structured data that we can parse automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    TextField("https://www.example.com/recipe/...", text: $urlText)
                        .textFieldStyle(.plain)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .padding(14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                        .padding(.horizontal)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    Button {
                        importFromURL()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text(isLoading ? "Importing..." : "Import Recipe")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "2A9D8F"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Import from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showEditor) {
                if let recipe = prefilledRecipe {
                    AddRecipeView(existingRecipe: recipe)
                }
            }
        }
    }
    
    private func importFromURL() {
        var cleanURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanURL.hasPrefix("http") { cleanURL = "https://" + cleanURL }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            if let result = await RecipeURLImporter.importRecipe(from: cleanURL) {
                let recipe = RecipeURLImporter.toRecipe(result)
                await MainActor.run {
                    prefilledRecipe = recipe
                    isLoading = false
                    showEditor = true
                }
            } else {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Couldn't parse a recipe from that URL. Try a different link or paste the text manually."
                }
            }
        }
    }
}
