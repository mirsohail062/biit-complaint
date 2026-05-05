// Views/Auth/LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var identifier = ""
    @State private var password   = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.biitBlue, Color.biitBlue.opacity(0.75)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // ── Logo / Header ─────────────────────────────────
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 70))
                            .foregroundColor(Color.biitGold)
                        Text("BIIT Complaint System")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        Text("Barani Institute of Information Technology")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)

                    // ── Login Card ────────────────────────────────────
                    VStack(spacing: 20) {
                        Text("Sign In")
                            .font(.title2.bold())
                            .foregroundColor(Color.biitBlue)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        BIITTextField(
                            placeholder: "Registration / Employee / Admin ID",
                            text: $identifier,
                            icon: "person.fill"
                        )
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                        BIITTextField(
                            placeholder: "Password",
                            text: $password,
                            icon: "lock.fill",
                            isSecure: true
                        )

                        ErrorBanner(message: authVM.errorMessage)

                        PrimaryButton(
                            title: "Login",
                            icon: "arrow.right.circle",
                            isLoading: authVM.isLoading
                        ) {
                            Task { await authVM.login(identifier: identifier, password: password) }
                        }

                        Text("Contact your administrator to get access.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background(Color.biitBg)
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}
