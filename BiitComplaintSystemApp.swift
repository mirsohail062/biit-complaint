// BIITComplaintSystemApp.swift
import SwiftUI

@main
struct BIITComplaintSystemApp: App {
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
}

// MARK: - RootView (routes to correct dashboard)
struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if !authVM.isLoggedIn {
                LoginView()
            } else {
                switch authVM.currentRole {
                case "student":   StudentDashboardView()
                case "teacher":   TeacherDashboardView()
                case "committee": CommitteeDashboardView()
                case "admin":     AdminDashboardView()
                default:          LoginView()
                }
            }
        }
        .animation(.easeInOut, value: authVM.isLoggedIn)
    }
}
