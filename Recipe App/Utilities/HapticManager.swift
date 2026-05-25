import UIKit

enum HapticManager {
    
    /// Light tap — toggling favorites, checking grocery items, selecting categories
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    /// Medium tap — saving a recipe, completing a cook step, adding ingredients
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    /// Heavy tap — deleting, clearing grocery list
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    /// Success — recipe saved, cooking complete, grocery list fully checked
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    /// Error — validation failed, delete confirmation
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    /// Selection changed — stepping through tabs, pickers, rating stars
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
