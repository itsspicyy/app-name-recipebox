import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var notificationsGranted = false
    let onComplete: () -> Void
    
    private let teal = Color(hex: "2A9D8F")
    private let navy = Color(hex: "264653")
    private let cream = Color(hex: "F8F6F0")
    private let orange = Color(hex: "F4A261")
    private let coral = Color(hex: "E76F51")
    private let gold = Color(hex: "E9C46A")
    private let green = Color(hex: "8AC926")
    
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button {
                            withAnimation { currentPage = totalPages - 1 }
                        } label: {
                            Text("Skip")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
                .frame(height: 44)
                
                // Page content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    importPage.tag(1)
                    cookingPage.tag(2)
                    planPage.tag(3)
                    notificationPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { idx in
                            Circle()
                                .fill(idx == currentPage ? teal : teal.opacity(0.2))
                                .frame(width: idx == currentPage ? 10 : 7, height: idx == currentPage ? 10 : 7)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Action button
                    if currentPage == totalPages - 1 {
                        Button {
                            HapticManager.success()
                            AppSettings.shared.hasCompletedOnboarding = true
                            onComplete()
                        } label: {
                            Text("Get Started")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(teal)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 32)
                    } else {
                        Button {
                            HapticManager.selection()
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Continue")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(teal)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - Page 1: Welcome
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration: Recipe box with cards and utensils
            ZStack {
                // Shadow beneath box
                Ellipse()
                    .fill(navy.opacity(0.06))
                    .frame(width: 200, height: 30)
                    .offset(y: 95)
                
                // Box body
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(colors: [orange.opacity(0.3), orange.opacity(0.15)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 180, height: 120)
                    .offset(y: 30)
                
                // Box rim
                RoundedRectangle(cornerRadius: 12)
                    .fill(orange.opacity(0.5))
                    .frame(width: 190, height: 24)
                    .offset(y: -28)
                
                // Recipe card 1 (left, peeking)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 70, height: 90)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    .rotationEffect(.degrees(-12))
                    .offset(x: -50, y: -20)
                    .overlay(
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2).fill(teal.opacity(0.4)).frame(width: 40, height: 4)
                            RoundedRectangle(cornerRadius: 2).fill(teal.opacity(0.2)).frame(width: 30, height: 3)
                            RoundedRectangle(cornerRadius: 2).fill(teal.opacity(0.2)).frame(width: 35, height: 3)
                        }
                        .offset(x: -50, y: -30)
                        .rotationEffect(.degrees(-12))
                    )
                
                // Recipe card 2 (center, tallest)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 75, height: 100)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    .offset(y: -30)
                    .overlay(
                        VStack(spacing: 4) {
                            Circle().fill(coral.opacity(0.3)).frame(width: 30, height: 30)
                            RoundedRectangle(cornerRadius: 2).fill(navy.opacity(0.3)).frame(width: 45, height: 4)
                            RoundedRectangle(cornerRadius: 2).fill(navy.opacity(0.15)).frame(width: 35, height: 3)
                        }
                        .offset(y: -40)
                    )
                
                // Recipe card 3 (right, peeking)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 70, height: 85)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    .rotationEffect(.degrees(10))
                    .offset(x: 50, y: -15)
                    .overlay(
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2).fill(gold.opacity(0.4)).frame(width: 40, height: 4)
                            RoundedRectangle(cornerRadius: 2).fill(gold.opacity(0.2)).frame(width: 30, height: 3)
                            RoundedRectangle(cornerRadius: 2).fill(gold.opacity(0.2)).frame(width: 36, height: 3)
                        }
                        .offset(x: 50, y: -28)
                        .rotationEffect(.degrees(10))
                    )
                
                // Heart floating above
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(coral.opacity(0.6))
                    .offset(x: 70, y: -75)
                
                // Star floating above
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(gold.opacity(0.6))
                    .offset(x: -65, y: -80)
            }
            .frame(height: 220)
            
            VStack(spacing: 12) {
                Text("Welcome to")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("Recipe Box")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(navy)
                Text("Your personal kitchen companion.\nSave, organize, and cook your favorite recipes — all in one place.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Page 2: Import
    
    private var importPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration: Phone with recipe flowing in from multiple sources
            ZStack {
                // Shadow
                Ellipse()
                    .fill(navy.opacity(0.06))
                    .frame(width: 180, height: 25)
                    .offset(y: 110)
                
                // Phone body
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(width: 140, height: 200)
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                
                // Phone screen
                RoundedRectangle(cornerRadius: 14)
                    .fill(cream)
                    .frame(width: 124, height: 178)
                
                // Recipe content on screen
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(teal.opacity(0.3))
                        .frame(width: 80, height: 40)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(navy.opacity(0.3))
                        .frame(width: 70, height: 5)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(navy.opacity(0.15))
                        .frame(width: 60, height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(navy.opacity(0.15))
                        .frame(width: 65, height: 4)
                }
                .offset(y: -15)
                
                // Camera icon (top-left)
                ZStack {
                    Circle().fill(coral).frame(width: 44, height: 44)
                    Image(systemName: "camera.fill").font(.system(size: 18)).foregroundStyle(.white)
                }
                .shadow(color: coral.opacity(0.3), radius: 6, y: 3)
                .offset(x: -90, y: -60)
                
                // Link icon (top-right)
                ZStack {
                    Circle().fill(teal).frame(width: 44, height: 44)
                    Image(systemName: "link").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                }
                .shadow(color: teal.opacity(0.3), radius: 6, y: 3)
                .offset(x: 90, y: -30)
                
                // Text icon (bottom-left)
                ZStack {
                    Circle().fill(orange).frame(width: 44, height: 44)
                    Image(systemName: "doc.text.fill").font(.system(size: 18)).foregroundStyle(.white)
                }
                .shadow(color: orange.opacity(0.3), radius: 6, y: 3)
                .offset(x: -85, y: 50)
                
                // Arrows pointing to phone
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(coral.opacity(0.4))
                    .offset(x: -58, y: -55)
                
                Image(systemName: "arrow.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(teal.opacity(0.4))
                    .offset(x: 58, y: -25)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(orange.opacity(0.4))
                    .offset(x: -55, y: 50)
                
                // Sparkle
                Image(systemName: "sparkle")
                    .font(.system(size: 16))
                    .foregroundStyle(gold)
                    .offset(x: 80, y: -80)
            }
            .frame(height: 240)
            
            VStack(spacing: 12) {
                Text("Import Recipes Instantly")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(navy)
                Text("Snap a photo, paste a URL, type it out, or paste text from anywhere. Recipe Box auto-detects ingredients and steps for you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Page 3: Cooking Mode
    
    private var cookingPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration: Dark cooking mode screen with step text and controls
            ZStack {
                Ellipse()
                    .fill(navy.opacity(0.06))
                    .frame(width: 180, height: 25)
                    .offset(y: 115)
                
                // Dark phone
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1A1A2E"))
                    .frame(width: 155, height: 210)
                    .shadow(color: .black.opacity(0.2), radius: 15, y: 5)
                
                // Step content
                VStack(spacing: 12) {
                    // Phase label
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").font(.system(size: 8))
                        Text("COOKING").font(.system(size: 9, weight: .bold)).tracking(2)
                    }
                    .foregroundStyle(coral)
                    
                    Text("Step 3")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    Text("Fold in the chocolate chips and pour into pan")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    // Timer badge
                    HStack(spacing: 4) {
                        Image(systemName: "timer").font(.system(size: 10))
                        Text("25:00").font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(teal)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(teal.opacity(0.15))
                    .clipShape(Capsule())
                    
                    // Nav buttons
                    HStack(spacing: 30) {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left").font(.system(size: 8))
                            Text("Prev").font(.system(size: 10))
                        }
                        .foregroundStyle(.white.opacity(0.4))
                        
                        HStack(spacing: 2) {
                            Text("Next").font(.system(size: 10, weight: .semibold))
                            Image(systemName: "chevron.right").font(.system(size: 8))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(teal)
                        .clipShape(Capsule())
                    }
                }
                
                // Voice icon floating
                ZStack {
                    Circle().fill(teal).frame(width: 40, height: 40)
                    Image(systemName: "speaker.wave.2.fill").font(.system(size: 16)).foregroundStyle(.white)
                }
                .shadow(color: teal.opacity(0.3), radius: 6, y: 3)
                .offset(x: 85, y: -70)
                
                // Sound waves
                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundStyle(teal.opacity(0.3))
                    .offset(x: 85, y: -30)
            }
            .frame(height: 250)
            
            VStack(spacing: 12) {
                Text("Cook Hands-Free")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(navy)
                Text("Step-by-step Cooking Mode keeps your screen on, reads steps aloud, and tracks timers — so your hands stay on the food.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Page 4: Plan, Shop, Cook
    
    private var planPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration: Calendar + grocery list + pantry
            ZStack {
                Ellipse()
                    .fill(navy.opacity(0.06))
                    .frame(width: 220, height: 25)
                    .offset(y: 100)
                
                // Calendar card (left)
                VStack(spacing: 0) {
                    // Calendar header
                    RoundedRectangle(cornerRadius: 8)
                        .fill(coral)
                        .frame(width: 100, height: 24)
                        .overlay(
                            Text("This Week").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                        )
                    
                    // Calendar body
                    VStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { row in
                            HStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(row == 1 ? teal.opacity(0.3) : navy.opacity(0.06))
                                    .frame(width: 24, height: 12)
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(navy.opacity(0.15))
                                    .frame(height: 3)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.white)
                    .clipShape(
                        .rect(bottomLeadingRadius: 8, bottomTrailingRadius: 8)
                    )
                    .frame(width: 100)
                }
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                .offset(x: -65, y: -15)
                .rotationEffect(.degrees(-5))
                
                // Grocery list card (center)
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "cart.fill").font(.system(size: 10)).foregroundStyle(green)
                        Text("Grocery List").font(.system(size: 9, weight: .bold)).foregroundStyle(navy)
                    }
                    
                    ForEach(0..<4, id: \.self) { i in
                        HStack(spacing: 6) {
                            Image(systemName: i < 2 ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 10))
                                .foregroundStyle(i < 2 ? teal : .secondary.opacity(0.3))
                            RoundedRectangle(cornerRadius: 1)
                                .fill(i < 2 ? navy.opacity(0.1) : navy.opacity(0.2))
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                                .strikethrough(i < 2)
                        }
                    }
                }
                .padding(12)
                .frame(width: 110)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .offset(y: 10)
                
                // Pantry card (right)
                VStack(spacing: 5) {
                    HStack(spacing: 3) {
                        Image(systemName: "refrigerator.fill").font(.system(size: 9)).foregroundStyle(Color(hex: "BC6C25"))
                        Text("Pantry").font(.system(size: 8, weight: .bold)).foregroundStyle(navy)
                    }
                    
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 4) {
                            Circle().fill(teal.opacity(0.3)).frame(width: 6, height: 6)
                            RoundedRectangle(cornerRadius: 1).fill(navy.opacity(0.15)).frame(height: 3).frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(8)
                .frame(width: 80)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                .offset(x: 70, y: -25)
                .rotationEffect(.degrees(5))
                
                // Connecting lines
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(teal.opacity(0.3))
                    .offset(x: -8, y: -10)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(teal.opacity(0.3))
                    .offset(x: 50, y: 0)
                
                // Sparkles
                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                    .foregroundStyle(gold)
                    .offset(x: -90, y: -65)
                
                Image(systemName: "sparkle")
                    .font(.system(size: 10))
                    .foregroundStyle(gold.opacity(0.5))
                    .offset(x: 100, y: -60)
            }
            .frame(height: 220)
            
            VStack(spacing: 12) {
                Text("Plan, Shop, Cook")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(navy)
                Text("Plan your weekly meals, auto-generate grocery lists organized by aisle, and track what's already in your pantry.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Page 5: Notifications
    
    private var notificationPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration: Bell with notification banners
            ZStack {
                Ellipse()
                    .fill(navy.opacity(0.06))
                    .frame(width: 160, height: 22)
                    .offset(y: 100)
                
                // Large bell
                ZStack {
                    Circle()
                        .fill(teal.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(teal.opacity(0.08))
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "bell.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(teal)
                }
                
                // Notification banner 1 (top-right)
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").font(.system(size: 10)).foregroundStyle(coral)
                    Text("Time to cook!").font(.system(size: 10, weight: .medium)).foregroundStyle(navy)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                .offset(x: 55, y: -65)
                
                // Notification banner 2 (left)
                HStack(spacing: 6) {
                    Image(systemName: "calendar").font(.system(size: 10)).foregroundStyle(gold)
                    Text("Plan your week").font(.system(size: 10, weight: .medium)).foregroundStyle(navy)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                .offset(x: -50, y: 65)
                
                // Notification badge
                Circle()
                    .fill(coral)
                    .frame(width: 20, height: 20)
                    .overlay(Text("3").font(.system(size: 10, weight: .bold)).foregroundStyle(.white))
                    .offset(x: 22, y: -30)
            }
            .frame(height: 220)
            
            VStack(spacing: 12) {
                Text("Stay on Track")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(navy)
                Text("Get gentle reminders for meal plans, dinner suggestions, and cooking timers — even when the app is closed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                
                if !notificationsGranted {
                    Button {
                        HapticManager.medium()
                        NotificationManager.shared.requestPermission { granted in
                            notificationsGranted = granted
                            if granted {
                                NotificationManager.shared.refreshScheduledNotifications()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bell.badge.fill")
                            Text("Enable Notifications")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(teal)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(teal.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                    
                    Text("You can change this anytime in Settings.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(teal)
                        Text("Notifications enabled!")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(teal)
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
