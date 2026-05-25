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
                    .onTapGesture { if editable { rating = rating == star ? nil : star } }
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
    }
}
