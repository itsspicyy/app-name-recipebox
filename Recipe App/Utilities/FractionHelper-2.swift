import Foundation

struct FractionHelper {
    
    static func toDouble(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let normalized = replaceUnicodeFractions(trimmed)
        let parts = normalized.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if parts.count == 2, let whole = Double(parts[0]), let frac = parseSingleFraction(parts[1]) { return whole + frac }
        if parts.count == 1 {
            if let frac = parseSingleFraction(parts[0]) { return frac }
            if let num = Double(parts[0]) { return num }
        }
        return nil
    }
    
    private static func parseSingleFraction(_ str: String) -> Double? {
        let c = str.split(separator: "/")
        guard c.count == 2, let n = Double(c[0]), let d = Double(c[1]), d != 0 else { return nil }
        return n / d
    }
    
    private static func replaceUnicodeFractions(_ input: String) -> String {
        let map: [Character: String] = ["½":"1/2","⅓":"1/3","⅔":"2/3","¼":"1/4","¾":"3/4","⅕":"1/5","⅖":"2/5","⅗":"3/5","⅘":"4/5","⅙":"1/6","⅚":"5/6","⅛":"1/8","⅜":"3/8","⅝":"5/8","⅞":"7/8"]
        var result = input
        for (char, replacement) in map { result = result.replacingOccurrences(of: String(char), with: " \(replacement)") }
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    static func toFractionString(_ value: Double) -> String {
        if value == value.rounded() && value >= 1 { return String(Int(value)) }
        if value == 0 { return "0" }
        let whole = Int(value); let fractional = value - Double(whole)
        if let fractionStr = matchCommonFraction(fractional) { return whole > 0 ? "\(whole) \(fractionStr)" : fractionStr }
        return formatDecimal(value)
    }
    
    private static func matchCommonFraction(_ value: Double) -> String? {
        let tolerance = 0.01
        let fractions: [(Double, String)] = [(1.0/8,"1/8"),(1.0/6,"1/6"),(1.0/5,"1/5"),(1.0/4,"1/4"),(1.0/3,"1/3"),(3.0/8,"3/8"),(2.0/5,"2/5"),(1.0/2,"1/2"),(3.0/5,"3/5"),(5.0/8,"5/8"),(2.0/3,"2/3"),(3.0/4,"3/4"),(4.0/5,"4/5"),(5.0/6,"5/6"),(7.0/8,"7/8")]
        for (frac, str) in fractions { if abs(value - frac) < tolerance { return str } }
        return nil
    }
    
    private static func formatDecimal(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        var result = String(format: "%.2f", value)
        while result.hasSuffix("0") { result = String(result.dropLast()) }
        if result.hasSuffix(".") { result = String(result.dropLast()) }
        return result
    }
    
    static func scale(_ quantity: String, by factor: Double) -> String {
        guard let value = toDouble(quantity) else { return quantity }
        return toFractionString(value * factor)
    }
}
