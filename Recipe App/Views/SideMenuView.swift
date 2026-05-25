import SwiftUI
import UIKit

struct SideMenuView: View {
    @Binding var isOpen: Bool
    @Binding var showSettings: Bool
    @Binding var selectedTab: HomeView.HomeTab
    @EnvironmentObject var store: RecipeStore
    
    @State private var showHelpTips = false
    
    private let navy = Color(hex: "264653")
    private let teal = Color(hex: "2A9D8F")
    private let cream = Color(hex: "F8F6F0")
    private let orange = Color(hex: "F4A261")
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Dimmed background
            if isOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
                    .transition(.opacity)
            }
            
            // Menu panel
            if isOpen {
                menuContent
                    .frame(width: 280)
                    .frame(maxHeight: .infinity)
                    .background(cream)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 24,
                            topTrailingRadius: 24
                        )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 5)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isOpen)
        .ignoresSafeArea()
        .sheet(isPresented: $showHelpTips) {
            HelpTipsView()
        }
    }
    
    // MARK: - Menu Content
    
    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "book.closed.fill")
                        .font(.title2)
                        .foregroundStyle(teal)
                    Spacer()
                    Button { close() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                Text("Recipe Box")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(navy)
                Text("\(store.recipes.count) recipe\(store.recipes.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 24)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Menu Items
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    
                    // Settings — opens sheet
                    menuItem(icon: "gearshape.fill", label: "Settings", color: teal) {
                        close()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showSettings = true
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    
                    // Navigation — switches tabs
                    menuItem(icon: "square.grid.2x2.fill", label: "All Recipes", color: navy, count: store.recipes.count) {
                        navigateTo(.all)
                    }
                    
                    menuItem(icon: "heart.fill", label: "Favorites", color: .red, count: store.favoriteRecipes.count) {
                        navigateTo(.favorites)
                    }
                    
                    menuItem(icon: "folder.fill", label: "Collections", color: orange, count: store.collections.count) {
                        navigateTo(.collections)
                    }
                    
                    menuItem(icon: "cart.fill", label: "Grocery List", color: Color(hex: "8AC926"), count: store.groceryList.count) {
                        navigateTo(.groceries)
                    }
                    
                    menuItem(icon: "refrigerator.fill", label: "Pantry", color: Color(hex: "BC6C25"), count: store.pantryItems.count) {
                        navigateTo(.pantry)
                    }
                    
                    menuItem(icon: "calendar", label: "Meal Plan", color: Color(hex: "E9C46A")) {
                        navigateTo(.mealPlan)
                    }
                    
                    Divider()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    
                    menuItem(icon: "envelope.fill", label: "Send Feedback", color: teal) {
                        close()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            FeedbackMailer.open()
                        }
                    }
                    
                    menuItem(icon: "square.and.arrow.up.fill", label: "Share App", color: .secondary) {
                        close()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            AppShareHelper.share()
                        }
                    }
                    
                    menuItem(icon: "questionmark.circle.fill", label: "Help & Tips", color: .secondary) {
                        close()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showHelpTips = true
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 2) {
                Text("Recipe Box v1.0.0")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Menu Item Row
    
    private func menuItem(
        icon: String,
        label: String,
        color: Color,
        count: Int? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                    .frame(width: 24, height: 24)
                
                Text(label)
                    .font(.body)
                    .foregroundStyle(navy)
                
                Spacer()
                
                if let count, count > 0 {
                    Text("\(count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(teal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(teal.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func navigateTo(_ tab: HomeView.HomeTab) {
        close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }
    }
    
    private func close() {
        isOpen = false
    }
}

// MARK: - Hamburger Button

struct HamburgerButton: View {
    @Binding var isMenuOpen: Bool
    
    private let navy = Color(hex: "264653")
    
    var body: some View {
        Button {
            isMenuOpen = true
        } label: {
            VStack(spacing: 5) {
                menuLine
                menuLine
                menuLine
            }
            .frame(width: 22, height: 22)
        }
    }
    
    private var menuLine: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(navy)
            .frame(width: 20, height: 2)
    }
}

// MARK: - Feedback Mailer

struct FeedbackMailer {
    static let feedbackEmail = "ethanhill2002@gmail.com"
    static let subject = "Recipe Box Feedback"
    
    static func open() {
        let deviceInfo = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        let body = """
        
        
        --- Please write your feedback above this line ---
        
        App Version: \(appVersion) (\(buildNumber))
        Device: \(deviceInfo.model)
        iOS: \(deviceInfo.systemVersion)
        """
        
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let url = URL(string: "mailto:\(feedbackEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - App Share Helper

struct AppShareHelper {
    // Replace with your actual App Store URL once published
    static let appStoreURL = "https://apps.apple.com/app/recipe-box/id0000000000"
    
    static func share() {
        let text = "Check out Recipe Box — a beautiful app for organizing your recipes, meal planning, and grocery lists! 🍳"
        var shareItems: [Any] = [text]
        
        if let url = URL(string: appStoreURL) {
            shareItems.append(url)
        }
        
        let activityVC = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: nil
        )
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topVC.present(activityVC, animated: true)
    }
}
