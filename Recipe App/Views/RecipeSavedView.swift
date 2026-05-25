import SwiftUI

struct RecipeSavedView: View {
    let recipeTitle: String
    let onDone: () -> Void
    let onAddMore: () -> Void
    
    @State private var showCheckmark = false
    @State private var showText = false
    @State private var showButtons = false
    
    private let teal = Color(hex: "2A9D8F")
    private let navy = Color(hex: "264653")
    private let cream = Color(hex: "F8F6F0")
    
    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // Animated checkmark circle
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(teal.opacity(0.2), lineWidth: 4)
                        .frame(width: 120, height: 120)
                    
                    // Fill circle
                    Circle()
                        .fill(teal.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showCheckmark ? 1.0 : 0.0)
                    
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(teal)
                        .scaleEffect(showCheckmark ? 1.0 : 0.0)
                        .rotationEffect(.degrees(showCheckmark ? 0 : -30))
                }
                
                // Text
                VStack(spacing: 10) {
                    Text("Recipe Saved!")
                        .font(.title.weight(.bold))
                        .foregroundStyle(navy)
                    
                    Text("\"\(recipeTitle)\" has been added to your Recipe Box.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(showText ? 1.0 : 0.0)
                .offset(y: showText ? 0 : 12)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onDone) {
                        Text("Done")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(teal)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button(action: onAddMore) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Another Recipe")
                        }
                        .font(.body.weight(.medium))
                        .foregroundStyle(teal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(teal.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showButtons ? 1.0 : 0.0)
                .offset(y: showButtons ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCheckmark = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                showText = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.55)) {
                showButtons = true
            }
        }
    }
}

#Preview {
    RecipeSavedView(
        recipeTitle: "Chocolate Chip Banana Bread",
        onDone: {},
        onAddMore: {}
    )
}
