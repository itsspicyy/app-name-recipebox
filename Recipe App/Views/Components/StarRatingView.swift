import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int?
    var maxRating: Int = 5
    var size: CGFloat = 24
    var editable: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: (rating ?? 0) >= star ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle((rating ?? 0) >= star ? Color(hex: "F4A261") : Color.gray.opacity(0.3))
                    .onTapGesture {
                        if editable {
                            HapticManager.selection()
                            rating = rating == star ? nil : star
                        }
                    }
                    .accessibilityHidden(true) // Handled as a unit below
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recipe rating")
        .accessibilityValue(rating.map { "\($0) out of \(maxRating) stars" } ?? "Not yet rated")
        .accessibilityAddTraits(editable ? .isButton : [])
        .accessibilityHint(editable ? "Swipe up or down to adjust rating" : "")
        .accessibilityAdjustableAction { direction in
            guard editable else { return }
            HapticManager.selection()
            switch direction {
            case .increment:
                let current = rating ?? 0
                rating = current < maxRating ? current + 1 : nil
            case .decrement:
                let current = rating ?? 0
                if current > 1 { rating = current - 1 }
                else { rating = nil }
            @unknown default:
                break
            }
        }
    }
}

struct StarRatingDisplay: View {
    let rating: Double?
    var maxRating: Int = 5
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            if let r = rating {
                ForEach(1...maxRating, id: \.self) { star in
                    Image(systemName: Double(star) <= r ? "star.fill" : (Double(star) - 0.5 <= r ? "star.leadinghalf.filled" : "star"))
                        .font(.system(size: size))
                        .foregroundStyle(Color(hex: "F4A261"))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel({
            guard let r = rating else { return "Not yet rated" }
            let formatted = r == r.rounded() ? String(Int(r)) : String(format: "%.1f", r)
            return "Rated \(formatted) out of \(maxRating) stars"
        }())
    }
}
