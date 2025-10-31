import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @StateObject private var authManager = AuthManager()
    @StateObject private var userManager = UserManager()
    @State private var usernameOrEmail = ""
    @State private var password = ""
    @State private var email = "" // Only for signup
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
            
            // Sign in/up fields
            VStack(spacing: 16) {
                if isSignUp {
                    TextField("Username", text: $usernameOrEmail)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                } else {
                    TextField("Username", text: $usernameOrEmail)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
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
            .background(isButtonDisabled ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 32)
            .disabled(isButtonDisabled)
            
            // Toggle between sign in and sign up
            Button(action: {
                isSignUp.toggle()
                errorMessage = ""
                usernameOrEmail = ""
                email = ""
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
    
    private var isButtonDisabled: Bool {
        if isSignUp {
            return usernameOrEmail.isEmpty || email.isEmpty || password.isEmpty || isLoading
        } else {
            return usernameOrEmail.isEmpty || password.isEmpty || isLoading
        }
    }
    
    private func handleAuth() {
        errorMessage = ""
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    // Check if username is available
                    let available = try await userManager.isUsernameAvailable(usernameOrEmail)
                    guard available else {
                        errorMessage = "Username is already taken"
                        isLoading = false
                        return
                    }
                    
                    // Create auth account with email
                    try await authManager.signUp(email: email, password: password)
                    
                    // Create user profile in Firestore
                    if let userId = authManager.currentUserId {
                        try await userManager.createUserProfile(
                            userId: userId,
                            email: email,
                            username: usernameOrEmail
                        )
                    }
                } else {
                    // Sign in: look up email from username
                    guard let email = try await userManager.getEmailFromUsername(usernameOrEmail) else {
                        errorMessage = "Username not found"
                        isLoading = false
                        return
                    }
                    
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
