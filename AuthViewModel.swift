// ViewModels/AuthViewModel.swift
import Foundation
import Combine
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentRole: String = ""
    @Published var currentUserId: Int = 0
    @Published var currentUserName: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    init() {
        // Restore session
        if let token = UserDefaults.standard.string(forKey: "auth_token"),
           !token.isEmpty {
            currentRole     = UserDefaults.standard.string(forKey: "user_role") ?? ""
            currentUserId   = UserDefaults.standard.integer(forKey: "user_id")
            currentUserName = UserDefaults.standard.string(forKey: "user_name") ?? ""
            isLoggedIn      = true
        }
    }

    func login(identifier: String, password: String) async {
        isLoading = true
        errorMessage = ""
        do {
            let payload = LoginRequest(identifier: identifier, password: password)
            let response = try await APIService.shared.request(
                endpoint: "/auth/login",
                method: "POST",
                body: payload,
                responseType: TokenResponse.self
            )
            // Persist session
            UserDefaults.standard.set(response.access_token, forKey: "auth_token")
            UserDefaults.standard.set(response.role,         forKey: "user_role")
            UserDefaults.standard.set(response.user_id,      forKey: "user_id")
            UserDefaults.standard.set(response.full_name,    forKey: "user_name")
            UserDefaults.standard.set(identifier,            forKey: "user_role_identifier")

            currentRole     = response.role
            currentUserId   = response.user_id
            currentUserName = response.full_name
            isLoggedIn      = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        ["auth_token","user_role","user_id","user_name","user_role_identifier"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        isLoggedIn      = false
        currentRole     = ""
        currentUserId   = 0
        currentUserName = ""
    }
}
