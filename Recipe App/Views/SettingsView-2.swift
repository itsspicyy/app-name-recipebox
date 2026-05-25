import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var showResetAlert = false
    @State private var showDeleteAllAlert = false
    @State private var showExportAlert = false
    
    private let cream = Color(hex: "F8F6F0")
    private let navy = Color(hex: "264653")
    private let teal = Color(hex: "2A9D8F")
    private let orange = Color(hex: "F4A261")
    private let coral = Color(hex: "E76F51")
    
    // MARK: - Binding Helpers
    
    private func bind<T>(_ keyPath: ReferenceWritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = $0 }
        )
    }
    
    var body: some View {
        NavigationStack {
            List {
                
                // ── General ──
                
                Section {
                    Stepper(value: bind(\.defaultServings), in: 1...24) {
                        Label {
                            HStack {
                                Text("Default Servings")
                                Spacer()
                                Text("\(settings.defaultServings)")
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            settingsIcon("person.2.fill", color: teal)
                        }
                    }
                    
                    Picker(selection: bind(\.defaultCategory)) {
                        ForEach(RecipeCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    } label: {
                        Label {
                            Text("Default Category")
                        } icon: {
                            settingsIcon("folder.fill", color: teal)
                        }
                    }
                    
                    Picker(selection: bind(\.defaultSortOption)) {
                        ForEach(RecipeSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    } label: {
                        Label {
                            Text("Default Sort")
                        } icon: {
                            settingsIcon("arrow.up.arrow.down", color: teal)
                        }
                    }
                } header: {
                    sectionHeader("General")
                }
                
                // ── Units & Measurements ──
                
                Section {
                    Picker(selection: bind(\.measurementSystem)) {
                        ForEach(MeasurementSystem.allCases) { system in
                            Label(system.rawValue, systemImage: system.icon).tag(system)
                        }
                    } label: {
                        Label {
                            Text("Measurement System")
                        } icon: {
                            settingsIcon("ruler.fill", color: orange)
                        }
                    }
                    
                    Picker(selection: bind(\.temperatureUnit)) {
                        ForEach(TemperatureUnit.allCases) { unit in
                            Text("\(unit.rawValue) (\(unit.symbol))").tag(unit)
                        }
                    } label: {
                        Label {
                            Text("Temperature")
                        } icon: {
                            settingsIcon("thermometer.medium", color: orange)
                        }
                    }
                } header: {
                    sectionHeader("Units & measurements")
                }
                
                // ── Cooking ──
                
                Section {
                    Toggle(isOn: bind(\.keepScreenOnWhileCooking)) {
                        Label {
                            Text("Keep Screen On")
                        } icon: {
                            settingsIcon("sun.max.fill", color: coral)
                        }
                    }
                    .tint(teal)
                    
                    Picker(selection: bind(\.timerSound)) {
                        ForEach(TimerSound.allCases) { sound in
                            Label(sound.rawValue, systemImage: sound.icon).tag(sound)
                        }
                    } label: {
                        Label {
                            Text("Timer Sound")
                        } icon: {
                            settingsIcon("bell.fill", color: coral)
                        }
                    }
                    
                    Toggle(isOn: bind(\.showTimerNotifications)) {
                        Label {
                            Text("Timer Notifications")
                        } icon: {
                            settingsIcon("app.badge.fill", color: coral)
                        }
                    }
                    .tint(teal)
                    
                    Toggle(isOn: bind(\.autoStartNextStep)) {
                        Label {
                            Text("Auto-Advance Steps")
                        } icon: {
                            settingsIcon("forward.fill", color: coral)
                        }
                    }
                    .tint(teal)
                    
                    Toggle(isOn: bind(\.confirmBeforeDeleting)) {
                        Label {
                            Text("Confirm Before Deleting")
                        } icon: {
                            settingsIcon("exclamationmark.triangle.fill", color: coral)
                        }
                    }
                    .tint(teal)
                } header: {
                    sectionHeader("Cooking")
                }
                
                // ── Grocery List ──
                
                Section {
                    Toggle(isOn: bind(\.groupGroceriesByAisle)) {
                        Label {
                            Text("Group by Aisle")
                        } icon: {
                            settingsIcon("cart.fill", color: Color(hex: "8AC926"))
                        }
                    }
                    .tint(teal)
                    
                    Toggle(isOn: bind(\.autoCrossCheckPantry)) {
                        Label {
                            Text("Cross-Check Pantry")
                        } icon: {
                            settingsIcon("checkmark.circle.fill", color: Color(hex: "8AC926"))
                        }
                    }
                    .tint(teal)
                    
                    Toggle(isOn: bind(\.autoRemoveCheckedItems)) {
                        Label {
                            Text("Auto-Remove Checked")
                        } icon: {
                            settingsIcon("xmark.circle.fill", color: Color(hex: "8AC926"))
                        }
                    }
                    .tint(teal)
                } header: {
                    sectionHeader("Grocery list")
                }
                
                // ── Meal Planning ──
                
                Section {
                    Toggle(isOn: bind(\.showMealSuggestions)) {
                        Label {
                            Text("Show Meal Suggestions")
                        } icon: {
                            settingsIcon("lightbulb.fill", color: Color(hex: "E9C46A"))
                        }
                    }
                    .tint(teal)
                    
                    Toggle(isOn: bind(\.mealPlanStartsOnMonday)) {
                        Label {
                            Text("Week Starts on Monday")
                        } icon: {
                            settingsIcon("calendar", color: Color(hex: "E9C46A"))
                        }
                    }
                    .tint(teal)
                } header: {
                    sectionHeader("Meal planning")
                }
                
                // ── Nutrition ──
                
                Section {
                    Toggle(isOn: bind(\.showNutritionEstimates)) {
                        Label {
                            Text("Show Nutrition Estimates")
                        } icon: {
                            settingsIcon("chart.pie.fill", color: Color(hex: "6A994E"))
                        }
                    }
                    .tint(teal)
                    
                    if settings.showNutritionEstimates {
                        Stepper(value: bind(\.dailyCalorieGoal), in: 1000...5000, step: 100) {
                            Label {
                                HStack {
                                    Text("Daily Calorie Goal")
                                    Spacer()
                                    Text("\(settings.dailyCalorieGoal)")
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                settingsIcon("flame.fill", color: Color(hex: "6A994E"))
                            }
                        }
                    }
                } header: {
                    sectionHeader("Nutrition")
                }
                
                // ── Data & Storage ──
                
                Section {
                    Toggle(isOn: bind(\.enableiCloudSync)) {
                        Label {
                            Text("iCloud Sync")
                        } icon: {
                            settingsIcon("icloud.fill", color: navy)
                        }
                    }
                    .tint(teal)
                    
                    Toggle(isOn: bind(\.autoBackup)) {
                        Label {
                            Text("Auto Backup")
                        } icon: {
                            settingsIcon("externaldrive.fill", color: navy)
                        }
                    }
                    .tint(teal)
                    
                    Button {
                        showExportAlert = true
                    } label: {
                        Label {
                            Text("Export All Recipes")
                                .foregroundStyle(.primary)
                        } icon: {
                            settingsIcon("square.and.arrow.up.fill", color: navy)
                        }
                    }
                    
                    recipeCountRow
                } header: {
                    sectionHeader("Data & storage")
                }
                
                // ── Danger Zone ──
                
                Section {
                    Button {
                        showResetAlert = true
                    } label: {
                        Label {
                            Text("Reset Settings to Defaults")
                                .foregroundStyle(coral)
                        } icon: {
                            settingsIcon("arrow.counterclockwise", color: coral)
                        }
                    }
                    
                    Button {
                        showDeleteAllAlert = true
                    } label: {
                        Label {
                            Text("Delete All Recipes")
                                .foregroundStyle(.red)
                        } icon: {
                            settingsIcon("trash.fill", color: .red)
                        }
                    }
                } header: {
                    sectionHeader("Danger zone")
                } footer: {
                    VStack(spacing: 4) {
                        Text("Recipe Box v1.0.0")
                        Text("Made with love 🍳")
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(cream)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(teal)
                }
            }
            .alert("Reset Settings?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { settings.resetToDefaults() }
            } message: {
                Text("This will restore all settings to their default values. Your recipes will not be affected.")
            }
            .alert("Delete All Recipes?", isPresented: $showDeleteAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    for recipe in store.recipes {
                        store.deleteRecipe(recipe)
                    }
                }
            } message: {
                Text("This will permanently delete all \(store.recipes.count) recipes. This action cannot be undone.")
            }
            .alert("Export Recipes", isPresented: $showExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Recipe export will be available in a future update.")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var recipeCountRow: some View {
        Label {
            HStack {
                Text("Total Recipes")
                Spacer()
                Text("\(store.recipes.count)")
                    .foregroundStyle(.secondary)
            }
        } icon: {
            settingsIcon("book.closed.fill", color: navy)
        }
    }
    
    private func settingsIcon(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: 6))
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(navy)
            .textCase(nil)
    }
}

#Preview {
    SettingsView()
        .environmentObject(RecipeStore())
}
