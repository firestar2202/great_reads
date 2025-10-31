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
        // Build the prompt with book summaries
        var booksText = ""
        for (index, book) in books.enumerated() {
            booksText += "\n\(index + 1). \(book.title) by \(book.author)"
            if let description = book.bookDescription {
                // Limit description to first 200 chars to save tokens
                let shortDesc = String(description.prefix(200))
                booksText += "\nSummary: \(shortDesc)...\n"
            }
        }
        
        let prompt = """
        Based on these \(books.count) books that someone has read recently, write a 1-sentence poetic "vibe" that captures their reading personality and taste.
        
        The vibe should be:
        - Written in second person "You are ... "
        - Describe their reading personality/aesthetic based on the books
        - be specific to the stories, don't write something too vague.
        - NOT a list of genres or book titles
        - Creative and evocative
        - NOT contain any book titles
        
        
        Here are their recent books:
        \(booksText)
        
        Generate the 1-sentence vibe now (ONLY the vibe, no other text):
        """
        
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 150,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ClaudeAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let vibe = claudeResponse.content.first?.text else {
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response from API"])
        }
        
        return vibe.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
