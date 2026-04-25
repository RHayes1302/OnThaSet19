//
//  EmailAuthView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 4/22/26.
//

import SwiftUI
import SwiftData

struct EmailAuthView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService

    enum Mode { case signIn, signUp }

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showResetAlert = false
    @State private var resetEmail = ""
    @State private var resetSent = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {

                    // LOGO
                    ZStack {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.yellow)
                        VStack(spacing: -2) {
                            Text("ON").font(.system(size: 16, weight: .black))
                            Text("THA").font(.system(size: 12, weight: .black))
                            Text("SET").font(.system(size: 20, weight: .black))
                        }
                        .foregroundColor(.black)
                        .offset(y: -4)
                    }
                    .padding(.top, 40)

                    // MODE TOGGLE
                    HStack(spacing: 0) {
                        modeButton("Sign In", selected: mode == .signIn) {
                            withAnimation { mode = .signIn }
                        }
                        modeButton("Sign Up", selected: mode == .signUp) {
                            withAnimation { mode = .signUp }
                        }
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .padding(.horizontal, 40)

                    // FIELDS
                    VStack(spacing: 16) {
                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                            TextField("", text: $email)
                                .placeholder(when: email.isEmpty) {
                                    Text("your@email.com").foregroundColor(.gray.opacity(0.5))
                                }
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                            HStack {
                                if showPassword {
                                    TextField("", text: $password)
                                        .placeholder(when: password.isEmpty) {
                                            Text("••••••••").foregroundColor(.gray.opacity(0.5))
                                        }
                                        .foregroundColor(.white)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("", text: $password)
                                        .placeholder(when: password.isEmpty) {
                                            Text("••••••••").foregroundColor(.gray.opacity(0.5))
                                        }
                                        .foregroundColor(.white)
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                        }

                        // Confirm Password (Sign Up only)
                        if mode == .signUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirm Password")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                SecureField("", text: $confirmPassword)
                                    .placeholder(when: confirmPassword.isEmpty) {
                                        Text("••••••••").foregroundColor(.gray.opacity(0.5))
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 40)

                    // FORGOT PASSWORD (Sign In only)
                    if mode == .signIn {
                        Button(action: {
                            resetEmail = email
                            showResetAlert = true
                        }) {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundColor(.yellow.opacity(0.8))
                        }
                    }

                    // AUTH BUTTON
                    Button(action: handleAuth) {
                        ZStack {
                            if authService.isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text(mode == .signIn ? "SIGN IN" : "CREATE ACCOUNT")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.yellow)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .disabled(authService.isLoading)

                    // ERROR
                    if let error = authService.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // BACK
                    Button(action: { dismiss() }) {
                        Text("GO BACK")
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .border(Color.yellow, width: 1)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Reset Password", isPresented: $showResetAlert) {
            TextField("Email address", text: $resetEmail)
                .autocapitalization(.none)
            Button("Send Reset Link") {
                Task {
                    let success = await authService.resetPassword(email: resetEmail)
                    if success { resetSent = true }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your email and we'll send a reset link.")
        }
        .alert("Email Sent", isPresented: $resetSent) {
            Button("OK") { }
        } message: {
            Text("Check your inbox for a password reset link.")
        }
    }

    // MARK: - Handle Auth Action

    private func handleAuth() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            authService.authError = "Please enter your email and password."
            return
        }

        if mode == .signUp {
            guard trimmedPassword == confirmPassword else {
                authService.authError = "Passwords do not match."
                return
            }
            guard trimmedPassword.count >= 6 else {
                authService.authError = "Password must be at least 6 characters."
                return
            }
        }

        Task {
            var success = false
            if mode == .signIn {
                success = await authService.signInWithEmail(email: trimmedEmail, password: trimmedPassword)
            } else {
                success = await authService.signUpWithEmail(email: trimmedEmail, password: trimmedPassword)
            }
            if success {
                await MainActor.run { dismiss() }
            }
        }
    }

    // MARK: - Mode Button
    private func modeButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(selected ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Color.yellow : Color.clear)
                .cornerRadius(10)
        }
    }
}

// MARK: - Placeholder Helper
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
