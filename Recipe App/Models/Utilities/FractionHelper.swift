import Foundation

struct FractionHelper {
    
    // MARK: - Parse fraction string to Double
    
    /// Parses a quantity string into a Double
    /// Supports: "2", "0.5", "1/4", "1 1/2", "½", "1½", "1 ½"
    static func toDouble(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        // Replace Unicode fraction characters with their decimal equivalents
        var normalized = replaceUnicodeFractions(trimmed)
        
        // Handle mixed number: "1 1/2" or "2 3/4"
        let parts = normalized.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        if parts.count == 2, let whole = Double(parts[0]), let frac = parseSingleFraction(parts[1]) {
            return whole + frac
        }
        
        if parts.count == 1 {
            // Try as a simple fraction "1/4"
            if let frac = parseSingleFraction(parts[0]) {
                return frac
            }
            // Try as a plain number "2" or "0.5"
            if let num = Double(parts[0]) {
                return num
            }
        }
        
        return nil
    }
    
    /// Parse a single fraction like "1/4" or "3/8"
    private static func parseSingleFraction(_ str: String) -> Double? {
        let components = str.split(separator: "/")
        guard components.count == 2,
              let numerator = Double(components[0]),
              let denominator = Double(components[1]),
              denominator != 0 else {
            return nil
        }
        return numerator / denominator
    }
    
    /// Replace Unicode fraction characters (½, ¼, etc.) with text fractions
    private static func replaceUnicodeFractions(_ input: String) -> String {
        let map: [Character: String] = [
            "½": "1/2",
            "⅓": "1/3",
            "⅔": "2/3",
            "¼": "1/4",
            "¾": "3/4",
            "⅕": "1/5",
            "⅖": "2/5",
            "⅗": "3/5",
            "⅘": "4/5",
            "⅙": "1/6",
            "⅚": "5/6",
            "⅛": "1/8",
            "⅜": "3/8",
            "⅝": "5/8",
            "⅞": "7/8"
        ]
        
        var result = input
        for (char, replacement) in map {
            result = result.replacingOccurrences(of: String(char), with: " \(replacement)")
        }
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Convert Double back to fraction string
    
    /// Converts a Double to the cleanest fraction string
    /// e.g. 0.25 -> "1/4", 1.5 -> "1 1/2", 2.0 -> "2", 0.333 -> "1/3"
    static func toFractionString(_ value: Double) -> String {
        // If it's a whole number, return as int
        if value == value.rounded() && value >= 1 {
            return String(Int(value))
        }
        
        // If it's zero
        if value == 0 { return "0" }
        
        // Split into whole and fractional parts
        let whole = Int(value)
        let fractional = value - Double(whole)
        
        // Try to match common fractions
        if let fractionStr = matchCommonFraction(fractional) {
            if whole > 0 {
                return "\(whole) \(fractionStr)"
            } else {
                return fractionStr
            }
        }
        
        // Fall back to decimal with clean formatting
        if whole > 0 {
            let remainder = value - Double(whole)
            if remainder == 0 {
                return String(whole)
            }
            // Show as decimal
            let formatted = formatDecimal(value)
            return formatted
        }
        
        return formatDecimal(value)
    }
    
    /// Match a fractional value (0.0 to 1.0) to a common kitchen fraction
    private static func matchCommonFraction(_ value: Double) -> String? {
        let tolerance = 0.01
        
        let fractions: [(Double, String)] = [
            (1.0/8.0, "1/8"),
            (1.0/6.0, "1/6"),
            (1.0/5.0, "1/5"),
            (1.0/4.0, "1/4"),
            (1.0/3.0, "1/3"),
            (3.0/8.0, "3/8"),
            (2.0/5.0, "2/5"),
            (1.0/2.0, "1/2"),
            (3.0/5.0, "3/5"),
            (5.0/8.0, "5/8"),
            (2.0/3.0, "2/3"),
            (3.0/4.0, "3/4"),
            (4.0/5.0, "4/5"),
            (5.0/6.0, "5/6"),
            (7.0/8.0, "7/8"),
        ]
        
        for (frac, str) in fractions {
            if abs(value - frac) < tolerance {
                return str
            }
        }
        
        return nil
    }
    
    /// Format a decimal cleanly (no trailing zeros)
    private static func formatDecimal(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        // Up to 2 decimal places
        let formatted = String(format: "%.2f", value)
        // Strip trailing zeros
        var result = formatted
        while result.hasSuffix("0") { result = String(result.dropLast()) }
        if result.hasSuffix(".") { result = String(result.dropLast()) }
        return result
    }
    
    // MARK: - Scale a quantity string
    
    /// Scale a quantity string by a factor and return a clean fraction string
    /// e.g. scale("1/2", by: 2.0) -> "1"
    /// e.g. scale("1", by: 0.5) -> "1/2"
    /// e.g. scale("2 1/4", by: 2.0) -> "4 1/2"
    static func scale(_ quantity: String, by factor: Double) -> String {
        guard let value = toDouble(quantity) else {
            // Can't parse - return as-is
            return quantity
        }
        let scaled = value * factor
        return toFractionString(scaled)
    }
}
