import SwiftUI

struct SplashView<Content: View>: View {
    let content: Content
    
    @State private var showSplashContent = false
    @State private var finished = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if finished {
                content
                    .transition(.opacity)
            } else {
                splashContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: finished)
        .onAppear {
            startAnimation()
        }
    }
    
    private var splashContent: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 18) {
                Image("RecipeBoxLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 165, height: 165)
                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                
                VStack(spacing: 6) {
                    Text("Recipe Box")
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                        .kerning(-0.5)
                        .foregroundColor(.black)
                    
                    Text("Your Kitchen Companion")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .kerning(-0.2)
                        .foregroundColor(.black.opacity(0.55))
                }
            }
            .opacity(showSplashContent ? 1.0 : 0.0)
            .scaleEffect(showSplashContent ? 1.0 : 0.88)
            .offset(y: showSplashContent ? 0 : 10)
        }
    }
    
    private func startAnimation() {
        withAnimation(.spring(response: 0.75, dampingFraction: 0.82)) {
            showSplashContent = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
            withAnimation(.easeInOut(duration: 0.45)) {
                finished = true
            }
        }
    }
}
