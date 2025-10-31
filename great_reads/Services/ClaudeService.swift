import Foundation

struct ClaudeResponse: Codable {
    let content: [ContentBlock]
    
    struct ContentBlock: Codable {
        let text: String
    }
}

class ClaudeService {
    // API key stored in Config.swift (which is gitignored)
    private let apiKey = Config.claudeAPIKey
    private let apiURL = "https://api.anthropic.com/v1/messages"
    
    func generateVibe(from books: [FirestoreBook]) async throws -> String {
        print("\n═══════════════════════════════════════════════════════════")
        print("🎨 GENERATING VIBE")
        print("═══════════════════════════════════════════════════════════")
        print("📚 Processing \(books.count) books\n")
        
        // Collect all book summaries
        var booksText = ""
        for (index, book) in books.enumerated() {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📖 Book \(index + 1)/\(books.count): \"\(book.title)\" by \(book.author)")
            
            if let description = book.bookDescription {
                print("📝 Description:")
                print("   \(description)\n")
                
                booksText += "\n\(index + 1). \"\(book.title)\" by \(book.author)\n"
                booksText += "   \(description)\n"
            } else {
                print("⚠️  NO DESCRIPTION - Skipping this book\n")
            }
        }
        
        print("═══════════════════════════════════════════════════════════")
        print("📤 Sending all book summaries to Claude in ONE API call...")
        print("═══════════════════════════════════════════════════════════\n")
        
        let prompt = """
        Based on these book descriptions someone has read recently, write out what vibe they give off.
        
        The vibe should be:
        - Written in second person "You are ... "
        - Relatively concise (5-15 words)
        - Match the tone of the books they are reading
        - NOT a list of genres or book titles
        
        Here are the books:
        \(booksText)
        
        Output ONLY the vibe sentence with no additional text:
        """
        
        print("📝 Full prompt being sent:")
        print("──────────────────────────────────────────────────")
        print(prompt)
        print("──────────────────────────────────────────────────\n")
        
        let response = try await makeAPIRequest(
            prompt: prompt,
            maxTokens: 150
        )
        
        // Extract only the first sentence
        let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstSentence = trimmedResponse.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? trimmedResponse
        
        // Add period if needed
        let finalVibe = firstSentence.hasSuffix(".") || firstSentence.hasSuffix("!") || firstSentence.hasSuffix("?") 
            ? firstSentence 
            : firstSentence + "."
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✨ FINAL VIBE:")
        print("   \(finalVibe)")
        print("═══════════════════════════════════════════════════════════\n")
        
        return finalVibe
    }
    
    private func makeAPIRequest(prompt: String, maxTokens: Int) async throws -> String {
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": maxTokens,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error: HTTP \(httpResponse.statusCode)")
            print("   \(errorMessage)")
            throw NSError(domain: "ClaudeAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let text = claudeResponse.content.first?.text else {
            print("❌ No response from API")
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response from API"])
        }
        
        print("📥 Received from Claude:")
        print("   \(text)\n")
        
        return text
    }
}

