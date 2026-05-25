import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var selectedDate = Date()
    @State private var showAddMeal = false
    @State private var selectedMealType: MealPlanEntry.MealType = .dinner
    @State private var showRecipePicker = false
    
    private var weekDates: [Date] {
        let cal = Calendar.current
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F8F6F0").ignoresSafeArea()
            
            VStack(spacing: 0) {
                weekSelector
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(weekDates, id: \.self) { date in
                            dayCard(for: date)
                        }
                        
                        // Generate grocery list button
                        if !store.mealPlan.isEmpty {
                            Button {
                                store.generateGroceryListFromMealPlan(for: weekDates)
                            } label: {
                                HStack {
                                    Image(systemName: "cart.fill")
                                    Text("Generate Grocery List for This Week")
                                }
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "2A9D8F"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Meal Plan")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Button {
                        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
        .sheet(isPresented: $showRecipePicker) {
            mealRecipePicker
        }
    }
    
    // MARK: - Week Selector
    
    private var weekSelector: some View {
        let cal = Calendar.current
        let formatter = DateFormatter()
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(weekDates, id: \.self) { date in
                    let isToday = cal.isDateInToday(date)
                    let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
                    let dayName = { formatter.dateFormat = "EEE"; return formatter.string(from: date) }()
                    let dayNum = cal.component(.day, from: date)
                    
                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 4) {
                            Text(dayName)
                                .font(.caption2.weight(.medium))
                            Text("\(dayNum)")
                                .font(.subheadline.weight(isToday ? .bold : .medium))
                            
                            let entryCount = store.mealPlanEntries(for: date).count
                            if entryCount > 0 {
                                Circle()
                                    .fill(Color(hex: "E76F51"))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(width: 44, height: 60)
                        .background(
                            isSelected ? Color(hex: "2A9D8F").opacity(0.15) :
                            (isToday ? Color(hex: "F4A261").opacity(0.1) : Color.clear)
                        )
                        .foregroundStyle(isSelected ? Color(hex: "2A9D8F") : (isToday ? Color(hex: "F4A261") : .primary))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Day Card
    
    private func dayCard(for date: Date) -> some View {
        let entries = store.mealPlanEntries(for: date)
        let cal = Calendar.current
        let isToday = cal.isDateInToday(date)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isToday ? Color(hex: "E76F51") : Color(hex: "264653"))
                
                if isToday {
                    Text("TODAY")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "E76F51"))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Button {
                    selectedDate = date
                    showRecipePicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                        .foregroundStyle(Color(hex: "2A9D8F"))
                }
            }
            
            if entries.isEmpty {
                Text("No meals planned")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(entries) { entry in
                    if let recipe = store.recipeForEntry(entry) {
                        HStack(spacing: 10) {
                            Text(mealTypeIcon(entry.mealType))
                                .font(.caption)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recipe.title)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                Text(entry.mealType.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                store.removeMealPlanEntry(entry)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red.opacity(0.5))
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .padding(.horizontal)
    }
    
    private func mealTypeIcon(_ type: MealPlanEntry.MealType) -> String {
        switch type {
        case .breakfast: return "🌅"
        case .lunch:     return "☀️"
        case .dinner:    return "🌙"
        case .snack:     return "🍿"
        }
    }
    
    // MARK: - Meal Recipe Picker
    
    private var mealRecipePicker: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Meal type picker
                Picker("Meal Type", selection: $selectedMealType) {
                    ForEach(MealPlanEntry.MealType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    ForEach(store.recipes) { recipe in
                        Button {
                            store.addToMealPlan(recipeID: recipe.id, date: selectedDate, mealType: selectedMealType)
                            showRecipePicker = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recipe.title)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 8) {
                                        Label(recipe.category.rawValue, systemImage: recipe.category.icon)
                                            .font(.caption2)
                                            .foregroundStyle(recipe.category.color)
                                        Label(recipe.totalTimeDisplay, systemImage: "clock")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(Color(hex: "2A9D8F"))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to \(selectedDate.formatted(.dateTime.weekday(.wide)))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showRecipePicker = false }
                }
            }
        }
    }
}
