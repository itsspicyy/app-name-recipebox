import Foundation
import Vision
import UIKit
import AVFoundation

class TextRecognizer {
    
    /// Recognize text from a UIImage using Vision framework
    static func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async { completion("") }
                return
            }
            
            // Sort observations top-to-bottom by their Y position (Vision uses bottom-left origin)
            let sorted = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
            
            let fullText = sorted.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                completion(fullText)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("OCR failed: \(error)")
                DispatchQueue.main.async { completion("") }
            }
        }
    }
    
    /// Extract key frames from a video and OCR each one, returning combined text
    static func recognizeText(fromVideoAt url: URL, completion: @escaping (String) -> Void) {
        Task {
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            
            let duration: CMTime
            do {
                duration = try await asset.load(.duration)
            } catch {
                await MainActor.run { completion("") }
                return
            }
            
            let durationSeconds = CMTimeGetSeconds(duration)
            guard durationSeconds > 0 else {
                await MainActor.run { completion("") }
                return
            }
            
            // Sample up to 10 frames evenly across the video
            let frameCount = min(10, max(3, Int(durationSeconds / 2.0)))
            let interval = durationSeconds / Double(frameCount)
            
            var allTexts: [String] = []
            
            for i in 0..<frameCount {
                let time = CMTime(seconds: Double(i) * interval + 0.5, preferredTimescale: 600)
                do {
                    let (cgImage, _) = try await generator.image(at: time)
                    let uiImage = UIImage(cgImage: cgImage)
                    let text = await withCheckedContinuation { cont in
                        recognizeText(from: uiImage) { result in
                            cont.resume(returning: result)
                        }
                    }
                    if !text.isEmpty { allTexts.append(text) }
                } catch {
                    continue
                }
            }
            
            let combined = deduplicateLines(allTexts.joined(separator: "\n"))
            await MainActor.run { completion(combined) }
        }
    }
    
    /// Remove duplicate lines that appear across multiple frames
    private static func deduplicateLines(_ text: String) -> String {
        var seen = Set<String>()
        var result: [String] = []
        
        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Normalize for comparison (lowercase, strip extra spaces)
            let normalized = trimmed.lowercased()
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            
            if !seen.contains(normalized) {
                seen.insert(normalized)
                result.append(trimmed)
            }
        }
        
        return result.joined(separator: "\n")
    }
}
