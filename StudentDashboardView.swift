
// Views/Dashboards/StudentDashboardView.swift
import SwiftUI

struct StudentDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showAddComplaint = false
    @State private var showViewComplaints = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.biitBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // ── Welcome Header ────────────────────────────
                        DashboardHeader(
                            greeting: "Welcome back,",
                            name: authVM.currentUserName,
                            role: "Student",
                            identifier: UserDefaults.standard.string(forKey: "user_role_identifier") ?? ""
                        )

                        // ── Quick Stats ───────────────────────────────
                        // ── Action Buttons ────────────────────────────
                        VStack(spacing: 16) {
                            DashboardActionCard(
                                title: "Add Complaint",
                                subtitle: "Submit a new complaint",
                                icon: "plus.bubble.fill",
                                color: Color.biitBlue
                            ) {
                                showAddComplaint = true
                            }

                            DashboardActionCard(
                                title: "View Complaints",
                                subtitle: "Track your submitted complaints",
                                icon: "list.bullet.clipboard.fill",
                                color: Color.biitGold
                            ) {
                                showViewComplaints = true
                            }
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") { authVM.logout() }
                        .foregroundColor(.red)
                }
            }
            .navigationDestination(isPresented: $showAddComplaint) {
                AddComplaintView()
            }
            .navigationDestination(isPresented: $showViewComplaints) {
                ViewComplaintsView()
            }
        }
    }
}


// MARK: - Shared dashboard components
struct DashboardHeader: View {
    let greeting: String
    let name: String
    let role: String
    let identifier: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [Color.biitBlue, Color.biitBlue.opacity(0.80)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "building.columns.fill")
                            .font(.title2)
                            .foregroundColor(Color.biitGold)
                        Text("BIIT Complaint System")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Text(greeting)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    Text(name)
                        .font(.title.bold())
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Label(role, systemImage: "person.fill")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(20)

                        if !identifier.isEmpty {
                            Text(identifier)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .frame(height: 180)
        }
    }
}

struct DashboardActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        }
    }
}
#Preview {
    StudentDashboardView()
        .environmentObject({
            let vm = AuthViewModel()
            vm.isLoggedIn = true
            vm.currentRole = "student"
            vm.currentUserName = "Amir Abbas"
            return vm
        }())
}
