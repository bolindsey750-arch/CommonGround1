import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

struct SignInView: View {
    var onLogin: () -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Welcome to CommonGround")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Sign in to connect with your community.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // MARK: - Email Login Fields
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button {
                    signInWithEmail()
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Sign In with Email")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                    }
                }

                Button("Create Account") {
                    registerWithEmail()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            // MARK: - Divider
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(.gray.opacity(0.3))
                Text("OR")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Rectangle().frame(height: 1).foregroundStyle(.gray.opacity(0.3))
            }
            .padding(.horizontal)

            // MARK: - Google Sign-In
            GoogleSignInButton(viewModel: .init(scheme: .light, style: .wide, state: .normal)) {
                signInWithGoogle()
            }
            .frame(height: 48)
            .padding(.horizontal)

            if !message.isEmpty {
                Text(message)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.vertical, 20)
    }

    // MARK: - EMAIL LOGIN
    private func signInWithEmail() {
        guard !email.isEmpty, !password.isEmpty else {
            message = "Please enter both email and password."
            return
        }
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            isLoading = false
            if let error = error {
                message = "Error: \(error.localizedDescription)"
            } else {
                onLogin()
            }
        }
    }

    // MARK: - EMAIL REGISTER
    private func registerWithEmail() {
        guard !email.isEmpty, !password.isEmpty else {
            message = "Please enter both email and password."
            return
        }
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            isLoading = false
            if let error = error {
                message = "Error: \(error.localizedDescription)"
            } else {
                onLogin()
            }
        }
    }

    // MARK: - GOOGLE SIGN-IN (Firebase 10+)
    private func signInWithGoogle() {
        guard FirebaseApp.app()?.options.clientID != nil else {
            message = "Missing Firebase Client ID."
            return
        }

        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        else {
            message = "Unable to access root view controller."
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { signInResult, error in
            if let error = error {
                message = "Google Sign-In failed: \(error.localizedDescription)"
                return
            }

            guard
                let result = signInResult,
                let idToken = result.user.idToken?.tokenString
            else {
                message = "Missing Google credentials."
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    message = "Firebase Sign-In error: \(error.localizedDescription)"
                } else {
                    onLogin()
                }
            }
        }
    }
}
