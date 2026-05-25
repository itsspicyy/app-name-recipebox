import SwiftUI
import AVFoundation
import Combine

struct CookingModeView: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss
    @State private var currentPhase: CookPhase = .ingredients
    @State private var currentStepIndex: Int = 0
    @State private var timerActive = false
    @State private var timerSeconds: Int = 0
    @State private var timer: Timer? = nil
    @State private var postCookRating: Int? = nil
    @State private var voiceEnabled = false
    @StateObject private var speaker = SpeechManager()
    
    enum CookPhase: String { case ingredients = "Ingredients", preparation = "Preparation", cooking = "Cooking", done = "Done!" }
    
    private var allSteps: [(phase: CookPhase, step: PrepStep)] {
        var s: [(CookPhase, PrepStep)] = []
        for st in recipe.preparationSteps { s.append((.preparation, st)) }
        for st in recipe.cookingSteps { s.append((.cooking, st)) }
        return s
    }
    
    var body: some View {
        ZStack {
            Color(hex: "1A1A2E").ignoresSafeArea()
            VStack(spacing: 0) {
                topBar; Spacer()
                if currentPhase == .ingredients { ingredientsView }
                else if currentPhase == .done { doneView }
                else { stepView }
                Spacer()
                if timerActive { timerDisplay }
                bottomControls
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture { if voiceEnabled && currentPhase != .ingredients && currentPhase != .done { goNext() } }
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false; timer?.invalidate(); speaker.stop() }
        .statusBarHidden()
    }
    
    private var topBar: some View {
        HStack {
            Button { timer?.invalidate(); speaker.stop(); dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.white.opacity(0.6)) }
            Spacer()
            VStack(spacing: 2) { Text(recipe.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white); Text(currentPhase.rawValue).font(.caption).foregroundStyle(Color(hex: "2A9D8F")) }
            Spacer()
            HStack(spacing: 12) {
                Button { voiceEnabled.toggle(); if !voiceEnabled { speaker.stop() } else if currentPhase != .ingredients && currentPhase != .done { speakCurrentStep() } } label: {
                    Image(systemName: voiceEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill").font(.body).foregroundStyle(voiceEnabled ? Color(hex: "2A9D8F") : .white.opacity(0.4))
                }
                if currentPhase != .ingredients && currentPhase != .done { Text("\(currentStepIndex + 1)/\(allSteps.count)").font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.6)) }
            }
        }
    }
    
    private var ingredientsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Gather Your Ingredients").font(.title.weight(.bold)).foregroundStyle(.white)
                ForEach(recipe.ingredients) { ing in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 12) { Image(systemName: "circle").font(.caption).foregroundStyle(Color(hex: "2A9D8F")); Text(ing.displayText).font(.title3).foregroundStyle(.white) }
                        if let sub = ing.substitution, !sub.isEmpty {
                            HStack(spacing: 6) { Image(systemName: "arrow.triangle.swap").font(.caption2); Text("Sub: \(sub)").font(.caption) }.foregroundStyle(Color(hex: "F4A261")).padding(.leading, 28)
                        }
                    }.padding(.vertical, 4)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var stepView: some View {
        let steps = allSteps
        guard currentStepIndex < steps.count else { return AnyView(EmptyView()) }
        let current = steps[currentStepIndex]
        return AnyView(
            VStack(spacing: 24) {
                HStack(spacing: 6) { Image(systemName: current.phase == .preparation ? "hands.sparkles.fill" : "flame.fill"); Text(current.phase.rawValue.uppercased()) }.font(.caption.weight(.bold)).tracking(2).foregroundStyle(Color(hex: "E76F51"))
                Text("Step \(currentStepIndex + 1)").font(.headline).foregroundStyle(.white.opacity(0.5))
                Text(current.step.text).font(.title2.weight(.medium)).foregroundStyle(.white).multilineTextAlignment(.center).lineSpacing(6).padding(.horizontal)
                if voiceEnabled { Text("Tap anywhere to go to the next step").font(.caption).foregroundStyle(.white.opacity(0.3)) }
                if let secs = current.step.timerSeconds, secs > 0, !timerActive {
                    Button { startTimer(seconds: secs) } label: {
                        HStack(spacing: 8) { Image(systemName: "timer"); Text("Start Timer (\(current.step.timerDisplay ?? ""))") }
                        .font(.body.weight(.medium)).foregroundStyle(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color(hex: "E76F51")).clipShape(Capsule())
                    }
                }
            }
        )
    }
    
    private var doneView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundStyle(Color(hex: "2A9D8F"))
            Text("You're done!").font(.largeTitle.weight(.bold)).foregroundStyle(.white)
            Text("Enjoy your \(recipe.title)!").font(.title3).foregroundStyle(.white.opacity(0.7))
            VStack(spacing: 12) {
                Text("How was it?").font(.subheadline).foregroundStyle(.white.opacity(0.6))
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button { postCookRating = star } label: {
                            Image(systemName: (postCookRating ?? 0) >= star ? "star.fill" : "star").font(.system(size: 36))
                                .foregroundStyle((postCookRating ?? 0) >= star ? Color(hex: "F4A261") : .white.opacity(0.3))
                        }
                    }
                }
                Button { store.logCookingSession(for: recipe, rating: postCookRating); dismiss() } label: {
                    Text(postCookRating != nil ? "Save & Close" : "Skip & Close").font(.body.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 32).padding(.vertical, 14).background(Color(hex: "2A9D8F")).clipShape(Capsule())
                }.padding(.top, 8)
            }.padding(.top, 16)
        }
    }
    
    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text(formattedTime(timerSeconds)).font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(timerSeconds <= 10 ? Color(hex: "E76F51") : Color(hex: "2A9D8F"))
            Button { timer?.invalidate(); timerActive = false; timerSeconds = 0 } label: { Text("Cancel").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.6)) }
        }.padding().background(Color.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var bottomControls: some View {
        HStack(spacing: 20) {
            if currentPhase != .ingredients {
                Button { goBack() } label: {
                    HStack(spacing: 4) { Image(systemName: "chevron.left"); Text("Prev") }.font(.body.weight(.medium)).foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 24).padding(.vertical, 14).background(Color.white.opacity(0.1)).clipShape(Capsule())
                }
            }
            Spacer()
            if currentPhase != .done {
                Button { goNext() } label: {
                    HStack(spacing: 4) { Text(currentPhase == .ingredients ? "Start" : "Next"); Image(systemName: "chevron.right") }.font(.body.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 32).padding(.vertical, 14).background(Color(hex: "2A9D8F")).clipShape(Capsule())
                }
            }
        }.padding(.top, 12)
    }
    
    private func goNext() {
        timer?.invalidate(); timerActive = false
        if currentPhase == .ingredients { if !allSteps.isEmpty { currentStepIndex = 0; currentPhase = allSteps[0].phase } else { currentPhase = .done } }
        else if currentStepIndex < allSteps.count - 1 { currentStepIndex += 1; currentPhase = allSteps[currentStepIndex].phase }
        else { currentPhase = .done }
        if voiceEnabled { speakCurrentStep() }
    }
    
    private func goBack() {
        timer?.invalidate(); timerActive = false; speaker.stop()
        if currentPhase == .done { if !allSteps.isEmpty { currentStepIndex = allSteps.count - 1; currentPhase = allSteps[currentStepIndex].phase } else { currentPhase = .ingredients } }
        else if currentStepIndex > 0 { currentStepIndex -= 1; currentPhase = allSteps[currentStepIndex].phase }
        else { currentPhase = .ingredients }
        if voiceEnabled { speakCurrentStep() }
    }
    
    private func speakCurrentStep() {
        guard currentPhase != .ingredients && currentPhase != .done, currentStepIndex < allSteps.count else { return }
        speaker.speak("Step \(currentStepIndex + 1). \(allSteps[currentStepIndex].step.text)")
    }
    
    private func startTimer(seconds: Int) {
        timerSeconds = seconds; timerActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if timerSeconds > 0 { timerSeconds -= 1 } else { t.invalidate(); if voiceEnabled { speaker.speak("Timer is done.") } }
        }
    }
    
    private func formattedTime(_ t: Int) -> String { String(format: "%02d:%02d", t / 60, t % 60) }
}

class SpeechManager: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(u)
    }
    func stop() { synthesizer.stopSpeaking(at: .immediate) }
}
