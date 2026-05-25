import SwiftUI

struct HelpTipsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedSection: HelpSection? = nil
    @State private var searchText: String = ""
    
    private let cream = Color(hex: "F8F6F0")
    private let navy = Color(hex: "264653")
    private let teal = Color(hex: "2A9D8F")
    private let orange = Color(hex: "F4A261")
    private let coral = Color(hex: "E76F51")
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header card
                    headerCard
                    
                    // Quick tips
                    quickTipsSection
                    
                    // FAQ sections
                    let filtered = filteredSections
                    if filtered.isEmpty {
                        noResultsView
                    } else {
                        ForEach(filtered) { section in
                            sectionCard(section)
                        }
                    }
                    
                    // Footer
                    footerCard
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(cream.ignoresSafeArea())
            .navigationTitle("Help & Tips")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search help topics...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(teal)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 40))
                .foregroundStyle(teal)
            
            Text("Welcome to Recipe Box")
                .font(.title3.weight(.bold))
                .foregroundStyle(navy)
            
            Text("Your personal kitchen companion. Here's everything you need to know to get the most out of the app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFF8E7"), .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: orange.opacity(0.15), radius: 8, y: 3)
    }
    
    // MARK: - Quick Tips
    
    private var quickTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(orange)
                Text("Quick Tips")
                    .font(.headline)
                    .foregroundStyle(navy)
            }
            
            VStack(spacing: 8) {
                quickTip(icon: "plus.circle.fill", color: teal, text: "Tap the + button on the home screen to add recipes manually, from photos, text, or a URL.")
                quickTip(icon: "hand.tap.fill", color: coral, text: "Long-press any recipe card for quick actions like favoriting, logging a cook, or deleting.")
                quickTip(icon: "arrow.left.arrow.right", color: orange, text: "Swipe between categories using the horizontal chips at the top of the recipe list.")
                quickTip(icon: "speaker.wave.3.fill", color: teal, text: "In Cooking Mode, enable voice readout to hear steps hands-free. Tap anywhere to advance.")
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
    
    private func quickTip(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .padding(.top, 1)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Section Card
    
    private func sectionCard(_ section: HelpSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    expandedSection = expandedSection == section ? nil : section
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(section.color, in: RoundedRectangle(cornerRadius: 8))
                    
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(navy)
                    
                    Spacer()
                    
                    Text("\(section.items.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(teal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(teal.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(expandedSection == section ? 90 : 0))
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded items
            if expandedSection == section {
                Divider()
                    .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(section.items.enumerated()), id: \.offset) { idx, item in
                        helpItemRow(item)
                        if idx < section.items.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
    
    private func helpItemRow(_ item: HelpItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(teal.opacity(0.6))
                    .frame(width: 24)
                    .padding(.top, 1)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.question)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(navy)
                    
                    Text(item.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - No Results
    
    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No matching topics")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Try a different search term.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Footer
    
    private var footerCard: some View {
        VStack(spacing: 12) {
            Text("Still have questions?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(navy)
            
            Text("Tap Send Feedback in the menu to reach us directly. We'd love to hear from you!")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                FeedbackMailer.open()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                    Text("Send Feedback")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(teal)
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
    
    // MARK: - Filtering
    
    private var filteredSections: [HelpSection] {
        let q = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return HelpSection.all }
        
        return HelpSection.all.compactMap { section in
            let matchingItems = section.items.filter {
                $0.question.lowercased().contains(q) || $0.answer.lowercased().contains(q)
            }
            if matchingItems.isEmpty && !section.title.lowercased().contains(q) {
                return nil
            }
            if matchingItems.isEmpty {
                return section
            }
            return HelpSection(
                title: section.title,
                icon: section.icon,
                color: section.color,
                items: matchingItems
            )
        }
    }
}

// MARK: - Data Model

struct HelpItem {
    let question: String
    let answer: String
}

struct HelpSection: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let items: [HelpItem]
    
    static func == (lhs: HelpSection, rhs: HelpSection) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Help Content

extension HelpSection {
    static let all: [HelpSection] = [
        
        // ── Adding Recipes ──
        HelpSection(
            title: "Adding Recipes",
            icon: "plus.circle.fill",
            color: Color(hex: "2A9D8F"),
            items: [
                HelpItem(
                    question: "How do I add a recipe?",
                    answer: "Tap the + button in the top-right corner of the home screen. You can type a recipe manually, paste text, import from a URL, or scan a photo from your camera roll."
                ),
                HelpItem(
                    question: "Can I import recipes from websites?",
                    answer: "Yes! Choose \"Import from URL\" and paste the link. Most recipe websites include structured data that the app can parse automatically, including ingredients, steps, and cook times."
                ),
                HelpItem(
                    question: "How does photo scanning work?",
                    answer: "Choose \"Upload from Camera Roll\" and select photos or even screen recordings of a recipe. The app uses text recognition (OCR) to extract the text, then automatically parses it into ingredients and steps."
                ),
                HelpItem(
                    question: "Can I import from a screenshot or screen recording?",
                    answer: "Absolutely. The photo importer accepts both images and videos. For screen recordings, the app samples multiple frames and combines the text it finds."
                ),
                HelpItem(
                    question: "What if the auto-detected recipe is wrong?",
                    answer: "After scanning or importing, you'll see a review screen with what was detected. Tap \"Use This\" to open the recipe editor where you can fix anything before saving."
                ),
            ]
        ),
        
        // ── Organizing Recipes ──
        HelpSection(
            title: "Organizing Recipes",
            icon: "folder.fill",
            color: Color(hex: "E76F51"),
            items: [
                HelpItem(
                    question: "What are categories and sub-categories?",
                    answer: "Categories are the main groupings like Breakfast, Lunch, Dinner, and Baking. Sub-categories are more specific tags like Quick Meal, Comfort Food, Vegetarian, or One-Pot. Each recipe has one category and can have multiple sub-categories."
                ),
                HelpItem(
                    question: "How do I favorite a recipe?",
                    answer: "Long-press a recipe card and tap \"Favorite\", or tap the heart icon inside the recipe detail view. All favorites appear in the Favorites tab."
                ),
                HelpItem(
                    question: "What are collections?",
                    answer: "Collections are custom groups you create — like \"Weeknight Dinners\", \"Party Food\", or \"Mom's Recipes\". Go to the Collections tab and tap \"New Collection\" to create one. You can add recipes to collections from the recipe detail screen."
                ),
                HelpItem(
                    question: "How do I search for recipes?",
                    answer: "Use the search bar at the top of the home screen. It searches recipe titles, descriptions, and ingredient names. You can also filter by category using the chips below the search bar."
                ),
                HelpItem(
                    question: "Can I rate recipes?",
                    answer: "Yes! You can rate a recipe from its detail view, or rate it after completing a cook in Cooking Mode. Ratings are stored in your cooking log and the average rating shows on each recipe card."
                ),
            ]
        ),
        
        // ── Cooking Mode ──
        HelpSection(
            title: "Cooking Mode",
            icon: "flame.fill",
            color: Color(hex: "E76F51"),
            items: [
                HelpItem(
                    question: "What is Cooking Mode?",
                    answer: "Cooking Mode is a distraction-free, step-by-step view designed for when you're actively cooking. It shows one step at a time in large text on a dark background, keeps your screen on, and includes built-in timers."
                ),
                HelpItem(
                    question: "How do I start Cooking Mode?",
                    answer: "Open any recipe and tap \"Start Cooking\" at the bottom of the detail view. You'll start with an ingredients checklist, then move through prep and cooking steps one at a time."
                ),
                HelpItem(
                    question: "Can the app read steps out loud?",
                    answer: "Yes! Tap the speaker icon in Cooking Mode to enable voice readout. Each step will be spoken aloud as you reach it. When voice mode is on, you can tap anywhere on the screen to advance to the next step — great for messy hands."
                ),
                HelpItem(
                    question: "How do timers work?",
                    answer: "If a step has a timer attached (like \"simmer for 15 minutes\"), a \"Start Timer\" button appears. The countdown displays in large text and alerts you when time is up."
                ),
                HelpItem(
                    question: "What happens when I finish cooking?",
                    answer: "You'll see a completion screen where you can rate the cook. This gets logged in your cooking history, which the app uses to track how often you make each recipe and to power meal suggestions."
                ),
            ]
        ),
        
        // ── Grocery List ──
        HelpSection(
            title: "Grocery List",
            icon: "cart.fill",
            color: Color(hex: "8AC926"),
            items: [
                HelpItem(
                    question: "How do I generate a grocery list?",
                    answer: "Go to the Groceries tab and tap \"Choose Recipes\". Select one or more recipes and tap \"Generate\". The app combines all ingredients, merges duplicates, and organizes them by store aisle."
                ),
                HelpItem(
                    question: "How are items organized?",
                    answer: "Items are automatically sorted into aisles like Produce, Dairy, Meat, Pantry, and Spices based on the ingredient name. This makes it easy to shop section by section."
                ),
                HelpItem(
                    question: "What does the pantry cross-check do?",
                    answer: "If you've added items to your Pantry, the grocery list will mark ingredients you already have with an \"IN PANTRY\" badge so you can skip them. You can toggle this in Settings."
                ),
                HelpItem(
                    question: "Can I check off items as I shop?",
                    answer: "Yes! Tap any item to check it off. A progress bar at the top shows how many items you've crossed off. You can clear the entire list from the menu when you're done."
                ),
            ]
        ),
        
        // ── Meal Planning ──
        HelpSection(
            title: "Meal Planning",
            icon: "calendar",
            color: Color(hex: "E9C46A"),
            items: [
                HelpItem(
                    question: "How do I plan meals?",
                    answer: "Go to the Plan tab. You'll see the current week with each day listed. Tap the + icon on any day, choose breakfast/lunch/dinner/snack, then pick a recipe from your collection."
                ),
                HelpItem(
                    question: "Can I generate a grocery list from my meal plan?",
                    answer: "Yes! At the bottom of the meal plan view, tap \"Generate Grocery List for This Week\" and it will combine the ingredients from all planned meals into a single shopping list."
                ),
                HelpItem(
                    question: "What are meal suggestions?",
                    answer: "The app suggests recipes based on the time of day, your cooking history, seasonal ingredients, ratings, and how recently you last made each dish. Suggestions appear at the top of the All Recipes tab. You can turn these off in Settings."
                ),
                HelpItem(
                    question: "How do I remove a planned meal?",
                    answer: "Tap the X button next to any planned meal to remove it from that day."
                ),
            ]
        ),
        
        // ── Pantry ──
        HelpSection(
            title: "Pantry",
            icon: "refrigerator.fill",
            color: Color(hex: "BC6C25"),
            items: [
                HelpItem(
                    question: "What is the Pantry?",
                    answer: "The Pantry is a list of ingredients you always have on hand — things like salt, olive oil, flour, and eggs. When you generate a grocery list, items in your pantry are flagged so you know you don't need to buy them."
                ),
                HelpItem(
                    question: "How do I add pantry items?",
                    answer: "Go to the Pantry tab and type an ingredient name in the text field at the top. Tap the + button to add it. You can also search your pantry to find specific items."
                ),
                HelpItem(
                    question: "How do I remove a pantry item?",
                    answer: "Swipe left on any pantry item and tap Delete, just like removing items in any standard iOS list."
                ),
            ]
        ),
        
        // ── Recipe Versions ──
        HelpSection(
            title: "Recipe Versions",
            icon: "clock.arrow.circlepath",
            color: Color(hex: "264653"),
            items: [
                HelpItem(
                    question: "What are recipe versions?",
                    answer: "Versions let you save variations of a recipe — like \"Original\", \"Low-Sodium\", or \"Mom's Tweak\". Each version stores its own ingredients, prep steps, cooking steps, and notes."
                ),
                HelpItem(
                    question: "How do I create a version?",
                    answer: "From the recipe detail view, you can save the current state as a named version. You can then make changes to the recipe and switch between versions at any time."
                ),
            ]
        ),
        
        // ── Scaling & Servings ──
        HelpSection(
            title: "Scaling & Servings",
            icon: "person.2.fill",
            color: Color(hex: "2A9D8F"),
            items: [
                HelpItem(
                    question: "Can I scale a recipe for more or fewer servings?",
                    answer: "Yes! In the recipe detail view, adjust the servings number. All ingredient quantities will automatically scale up or down proportionally. The app handles fractions cleanly — for example, scaling \"1/2 cup\" by 2x gives you \"1 cup\"."
                ),
                HelpItem(
                    question: "Does scaling affect the grocery list?",
                    answer: "The grocery list uses the base serving amounts from each recipe. If you want scaled amounts, adjust the servings on each recipe before generating the list."
                ),
                HelpItem(
                    question: "What units are supported?",
                    answer: "The app understands cups, tablespoons, teaspoons, ounces, pounds, grams, kilograms, milliliters, liters, and common unitless items like \"3 eggs\" or \"2 cloves garlic\". It also handles Unicode fractions like ½ and ¾."
                ),
            ]
        ),
        
        // ── Sharing ──
        HelpSection(
            title: "Sharing Recipes",
            icon: "square.and.arrow.up.fill",
            color: Color(hex: "F4A261"),
            items: [
                HelpItem(
                    question: "How do I share a recipe?",
                    answer: "Open a recipe and tap the share button. The app creates a formatted text version of the recipe along with a deep link. If the recipient has Recipe Box installed, they can tap the link to import it directly."
                ),
                HelpItem(
                    question: "What if the other person doesn't have the app?",
                    answer: "No problem — the share also includes a clean, formatted text version with all the ingredients and steps that works in any messaging app, email, or notes app."
                ),
                HelpItem(
                    question: "Will shared recipes include my cooking log and ratings?",
                    answer: "No. When a recipe is imported via a share link, it gets a fresh start — no cooking log, no rating, not favorited. Your personal data stays private."
                ),
            ]
        ),
        
        // ── Nutrition ──
        HelpSection(
            title: "Nutrition Estimates",
            icon: "chart.pie.fill",
            color: Color(hex: "6A994E"),
            items: [
                HelpItem(
                    question: "How are nutrition estimates calculated?",
                    answer: "The app uses a built-in database of common ingredients to estimate calories, protein, carbs, and fat. It converts your ingredient quantities to approximate grams and looks up per-100g nutrition data."
                ),
                HelpItem(
                    question: "How accurate are the estimates?",
                    answer: "These are rough estimates meant to give you a general idea. Actual nutrition depends on specific brands, preparation methods, and exact quantities. For precise tracking, use a dedicated nutrition app."
                ),
                HelpItem(
                    question: "Can I turn off nutrition estimates?",
                    answer: "Yes. Go to Settings and toggle off \"Show Nutrition Estimates\" in the Nutrition section."
                ),
            ]
        ),
        
        // ── Settings & Data ──
        HelpSection(
            title: "Settings & Data",
            icon: "gearshape.fill",
            color: Color(hex: "264653"),
            items: [
                HelpItem(
                    question: "Where is my data stored?",
                    answer: "All your recipes, collections, pantry items, and meal plans are stored locally on your device in the app's documents folder. Nothing is sent to any server."
                ),
                HelpItem(
                    question: "Can I change the measurement system?",
                    answer: "Yes. Go to Settings and choose between US Customary and Metric under \"Units & Measurements\". You can also switch between Fahrenheit and Celsius for temperatures."
                ),
                HelpItem(
                    question: "What does \"Keep Screen On\" do?",
                    answer: "When enabled, your screen won't dim or lock while you're in Cooking Mode. This is on by default so you can follow along without tapping your phone with messy hands."
                ),
                HelpItem(
                    question: "How do I reset everything?",
                    answer: "In Settings, scroll to the bottom. \"Reset Settings\" restores all preferences to defaults without touching your recipes. \"Delete All Recipes\" permanently removes every recipe — use with caution."
                ),
            ]
        ),
    ]
}

#Preview {
    HelpTipsView()
}
