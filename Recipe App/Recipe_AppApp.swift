import SwiftUI

@main
struct Recipe_AppApp: App {
    @StateObject private var store = RecipeStore()
    @State private var showImportAlert = false
    @State private var importedRecipeTitle = ""
    @State private var showOnboarding = !AppSettings.shared.hasCompletedOnboarding
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                SplashView {
                    HomeView()
                        .environmentObject(store)
                        .preferredColorScheme(.light)
                        .onOpenURL { url in
                            guard url.scheme == RecipeLinkHelper.scheme else { return }
                            if let recipe = RecipeLinkHelper.decodeRecipe(from: url) {
                                store.importRecipe(recipe)
                                importedRecipeTitle = recipe.title
                                showImportAlert = true
                            }
                        }
                        .alert("Recipe Added!", isPresented: $showImportAlert) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text("\"\(importedRecipeTitle)\" has been added to your Recipe Box.")
                        }
                }
                
                if showOnboarding {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showOnboarding = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showOnboarding)
        }
    }
}
