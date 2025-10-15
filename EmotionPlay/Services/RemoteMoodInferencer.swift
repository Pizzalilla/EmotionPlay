//
//  RemoteMoodInferecer.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 4/10/2025.
//

import Foundation

final class RemoteMoodInferencer: MoodInferencer {
  private let apiKey: String
  private let modelId = "microsoft/resnet-50"                 // ✅ ASCII hyphen
  private let host    = "https://api-inference.huggingface.co/models"

  init(apiKey: String) { self.apiKey = apiKey }

  func infer(fromImageData data: Data) async throws -> (Mood, Double) {
    let url = URL(string: "\(host)/\(modelId)")!
    print("🛰️ HF request →", url.absoluteString)

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))",
                 forHTTPHeaderField: "Authorization")
    req.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
    req.timeoutInterval = 45
    req.httpBody = data

    let (respData, resp) = try await fetchWithWarmupRetry(request: req)
    guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }

    print("✅ HF status:", http.statusCode)

    // Expected: [ { "label": "...", "score": 0.93 }, ... ]
    struct Pred: Decodable { let label: String; let score: Double }
    if let preds = try? JSONDecoder().decode([Pred].self, from: respData),
       let best  = preds.max(by: { $0.score < $1.score }) {
      return mapLabelToMood(best.label, score: best.score)
    }

    // If it wasn’t the usual array, print a snippet to help debug.
    let snippet = String(data: respData, encoding: .utf8) ?? "<non-utf8 body>"
    print("⚠️ Unexpected HF body:\n\(snippet)")
    return (.calm, 0.5)
  }

  // Retry once if model is cold (503)
  private func fetchWithWarmupRetry(request: URLRequest) async throws -> (Data, URLResponse) {
    func doFetch() async throws -> (Data, URLResponse) {
      let (d, r) = try await URLSession.shared.data(for: request)
      if let http = r as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
        let body = String(data: d, encoding: .utf8) ?? "<non-utf8>"
        throw NSError(domain: "HFInference", code: http.statusCode,
                      userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body)"])
      }
      return (d, r)
    }
    do {
      return try await doFetch()
    } catch let err as NSError where err.code == 503 {
      print("⏳ HF model warming (503). Retrying in 1s…")
      try await Task.sleep(nanoseconds: 1_000_000_000)
      return try await doFetch()
    }
  }

  private func mapLabelToMood(_ raw: String, score: Double) -> (Mood, Double) {
    let l = raw.lowercased()
    if l.contains("smile") || l.contains("joy") || l.contains("happy") { return (.happy, score) }
    if l.contains("sad") || l.contains("sorrow")                     { return (.sad, score) }
    if l.contains("angry") || l.contains("anger") || l.contains("mad"){ return (.energetic, max(0.3, score * 0.7)) }
    if l.contains("surprise") || l.contains("excite")                { return (.energetic, score) }
    return (.calm, score)
  }
}
