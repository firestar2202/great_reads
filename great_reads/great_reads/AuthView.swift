import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @StateObject private var authManager = AuthManager()
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App title/logo
            VStack(spacing: 8) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("GreatReads")
                    .font(.system(size: 36, weight: .bold))
                
                Text("Track your reading journey")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 40)
            
            // Email and password fields
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 32)
            
            // Error message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 32)
            }
            
            // Sign in/up button
            Button(action: handleAuth) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(email.isEmpty || password.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 32)
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            
            // Toggle between sign in and sign up
            Button(action: {
                isSignUp.toggle()
                errorMessage = ""
            }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .onSubmit {
            handleAuth()
        }
    }
    
    private func handleAuth() {
        errorMessage = ""
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, password: password)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    AuthView()
}
