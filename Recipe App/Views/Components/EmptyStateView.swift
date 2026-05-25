import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: "2A9D8F").opacity(0.4))
            
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "book.closed.fill",
        title: "Your recipe box is empty",
        subtitle: "Tap the + button to add your first recipe."
    )
    .background(Color(hex: "F8F6F0"))
}
