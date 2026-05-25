import Foundation
import SwiftUI
import Combine

// MARK: - Measurement System

enum MeasurementSystem: String, CaseIterable, Codable, Identifiable {
    case us = "US Customary"
    case metric = "Metric"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .us:     return "flag.fill"
        case .metric: return "globe.americas.fill"
        }
    }
}

// MARK: - Temperature Unit

enum TemperatureUnit: String, CaseIterable, Codable, Identifiable {
    case fahrenheit = "Fahrenheit"
    case celsius = "Celsius"
    
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .fahrenheit: return "°F"
        case .celsius:    return "°C"
        }
    }
}

// MARK: - Timer Sound

enum TimerSound: String, CaseIterable, Codable, Identifiable {
    case chime = "Chime"
    case bell = "Bell"
    case ding = "Ding"
    case alarm = "Alarm"
    case none = "None"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .chime: return "bell.fill"
        case .bell:  return "bell.badge.fill"
        case .ding:  return "bell.circle.fill"
        case .alarm: return "alarm.fill"
        case .none:  return "bell.slash.fill"
        }
    }
}

// MARK: - Sort Option

enum RecipeSortOption: String, CaseIterable, Codable, Identifiable {
    case dateModified = "Recently Modified"
    case dateCreated = "Date Created"
    case alphabetical = "Alphabetical"
    case rating = "Highest Rated"
    case cookTime = "Cook Time"
    case timesCooked = "Most Cooked"
    
    var id: String { rawValue }
}

// MARK: - App Settings

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let d = UserDefaults.standard
    
    private init() {
        d.register(defaults: [
            "defaultServings": 4,
            "defaultCategory": RecipeCategory.dinner.rawValue,
            "defaultSortOption": RecipeSortOption.dateModified.rawValue,
            "measurementSystem": MeasurementSystem.us.rawValue,
            "temperatureUnit": TemperatureUnit.fahrenheit.rawValue,
            "keepScreenOnWhileCooking": true,
            "timerSound": TimerSound.chime.rawValue,
            "showTimerNotifications": true,
            "autoStartNextStep": false,
            "confirmBeforeDeleting": true,
            "autoCrossCheckPantry": true,
            "groupGroceriesByAisle": true,
            "autoRemoveCheckedItems": false,
            "mealPlanStartDay": 1,
            "showMealSuggestions": true,
            "showNutritionEstimates": true,
            "dailyCalorieGoal": 2000,
            "enableiCloudSync": false,
            "autoBackup": true,
            "enableNotifications": true,
            "enableMealPlanReminders": true,
            "enableDailySuggestionNotification": true,
            "enableWeeklyPlanNotification": true,
            "enableTimerNotifications": true,
            "hasCompletedOnboarding": false
        ])
    }
    
    private func set(_ value: Any, forKey key: String) {
        d.set(value, forKey: key)
        DispatchQueue.main.async { self.objectWillChange.send() }
    }
    
    // ── General ──
    
    var defaultServings: Int {
        get { d.integer(forKey: "defaultServings") }
        set { set(newValue, forKey: "defaultServings") }
    }
    
    var defaultCategoryRaw: String {
        get { d.string(forKey: "defaultCategory") ?? RecipeCategory.dinner.rawValue }
        set { set(newValue, forKey: "defaultCategory") }
    }
    
    var defaultSortRaw: String {
        get { d.string(forKey: "defaultSortOption") ?? RecipeSortOption.dateModified.rawValue }
        set { set(newValue, forKey: "defaultSortOption") }
    }
    
    var defaultCategory: RecipeCategory {
        get { RecipeCategory(rawValue: defaultCategoryRaw) ?? .dinner }
        set { defaultCategoryRaw = newValue.rawValue }
    }
    
    var defaultSortOption: RecipeSortOption {
        get { RecipeSortOption(rawValue: defaultSortRaw) ?? .dateModified }
        set { defaultSortRaw = newValue.rawValue }
    }
    
    // ── Units ──
    
    var measurementSystemRaw: String {
        get { d.string(forKey: "measurementSystem") ?? MeasurementSystem.us.rawValue }
        set { set(newValue, forKey: "measurementSystem") }
    }
    
    var temperatureUnitRaw: String {
        get { d.string(forKey: "temperatureUnit") ?? TemperatureUnit.fahrenheit.rawValue }
        set { set(newValue, forKey: "temperatureUnit") }
    }
    
    var measurementSystem: MeasurementSystem {
        get { MeasurementSystem(rawValue: measurementSystemRaw) ?? .us }
        set { measurementSystemRaw = newValue.rawValue }
    }
    
    var temperatureUnit: TemperatureUnit {
        get { TemperatureUnit(rawValue: temperatureUnitRaw) ?? .fahrenheit }
        set { temperatureUnitRaw = newValue.rawValue }
    }
    
    // ── Cooking ──
    
    var keepScreenOnWhileCooking: Bool {
        get { d.bool(forKey: "keepScreenOnWhileCooking") }
        set { set(newValue, forKey: "keepScreenOnWhileCooking") }
    }
    
    var timerSoundRaw: String {
        get { d.string(forKey: "timerSound") ?? TimerSound.chime.rawValue }
        set { set(newValue, forKey: "timerSound") }
    }
    
    var showTimerNotifications: Bool {
        get { d.bool(forKey: "showTimerNotifications") }
        set { set(newValue, forKey: "showTimerNotifications") }
    }
    
    var autoStartNextStep: Bool {
        get { d.bool(forKey: "autoStartNextStep") }
        set { set(newValue, forKey: "autoStartNextStep") }
    }
    
    var confirmBeforeDeleting: Bool {
        get { d.bool(forKey: "confirmBeforeDeleting") }
        set { set(newValue, forKey: "confirmBeforeDeleting") }
    }
    
    var timerSound: TimerSound {
        get { TimerSound(rawValue: timerSoundRaw) ?? .chime }
        set { timerSoundRaw = newValue.rawValue }
    }
    
    // ── Grocery List ──
    
    var autoCrossCheckPantry: Bool {
        get { d.bool(forKey: "autoCrossCheckPantry") }
        set { set(newValue, forKey: "autoCrossCheckPantry") }
    }
    
    var groupGroceriesByAisle: Bool {
        get { d.bool(forKey: "groupGroceriesByAisle") }
        set { set(newValue, forKey: "groupGroceriesByAisle") }
    }
    
    var autoRemoveCheckedItems: Bool {
        get { d.bool(forKey: "autoRemoveCheckedItems") }
        set { set(newValue, forKey: "autoRemoveCheckedItems") }
    }
    
    // ── Meal Planning ──
    
    var mealPlanStartDayRaw: Int {
        get { d.integer(forKey: "mealPlanStartDay") }
        set { set(newValue, forKey: "mealPlanStartDay") }
    }
    
    var showMealSuggestions: Bool {
        get { d.bool(forKey: "showMealSuggestions") }
        set { set(newValue, forKey: "showMealSuggestions") }
    }
    
    var mealPlanStartsOnMonday: Bool {
        get { mealPlanStartDayRaw == 2 }
        set { mealPlanStartDayRaw = newValue ? 2 : 1 }
    }
    
    // ── Notifications ──
    
    var enableNotifications: Bool {
        get { d.bool(forKey: "enableNotifications") }
        set { set(newValue, forKey: "enableNotifications") }
    }
    
    var enableMealPlanReminders: Bool {
        get { d.bool(forKey: "enableMealPlanReminders") }
        set { set(newValue, forKey: "enableMealPlanReminders") }
    }
    
    var enableDailySuggestionNotification: Bool {
        get { d.bool(forKey: "enableDailySuggestionNotification") }
        set { set(newValue, forKey: "enableDailySuggestionNotification") }
    }
    
    var enableWeeklyPlanNotification: Bool {
        get { d.bool(forKey: "enableWeeklyPlanNotification") }
        set { set(newValue, forKey: "enableWeeklyPlanNotification") }
    }
    
    var enableTimerNotifications: Bool {
        get { d.bool(forKey: "enableTimerNotifications") }
        set { set(newValue, forKey: "enableTimerNotifications") }
    }
    
    // ── Nutrition ──
    
    var showNutritionEstimates: Bool {
        get { d.bool(forKey: "showNutritionEstimates") }
        set { set(newValue, forKey: "showNutritionEstimates") }
    }
    
    var dailyCalorieGoal: Int {
        get { d.integer(forKey: "dailyCalorieGoal") }
        set { set(newValue, forKey: "dailyCalorieGoal") }
    }
    
    // ── Data ──
    
    var enableiCloudSync: Bool {
        get { d.bool(forKey: "enableiCloudSync") }
        set { set(newValue, forKey: "enableiCloudSync") }
    }
    
    var autoBackup: Bool {
        get { d.bool(forKey: "autoBackup") }
        set { set(newValue, forKey: "autoBackup") }
    }
    
    // ── Onboarding ──
    
    var hasCompletedOnboarding: Bool {
        get { d.bool(forKey: "hasCompletedOnboarding") }
        set { set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    // ── Reset ──
    
    func resetToDefaults() {
        defaultServings = 4
        defaultCategoryRaw = RecipeCategory.dinner.rawValue
        defaultSortRaw = RecipeSortOption.dateModified.rawValue
        measurementSystemRaw = MeasurementSystem.us.rawValue
        temperatureUnitRaw = TemperatureUnit.fahrenheit.rawValue
        keepScreenOnWhileCooking = true
        timerSoundRaw = TimerSound.chime.rawValue
        showTimerNotifications = true
        autoStartNextStep = false
        confirmBeforeDeleting = true
        autoCrossCheckPantry = true
        groupGroceriesByAisle = true
        autoRemoveCheckedItems = false
        mealPlanStartDayRaw = 1
        showMealSuggestions = true
        showNutritionEstimates = true
        dailyCalorieGoal = 2000
        enableiCloudSync = false
        autoBackup = true
        enableNotifications = true
        enableMealPlanReminders = true
        enableDailySuggestionNotification = true
        enableWeeklyPlanNotification = true
        enableTimerNotifications = true
        NotificationManager.shared.handleNotificationToggle(enabled: true)
    }
}
