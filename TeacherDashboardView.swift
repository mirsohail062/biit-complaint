import SwiftUI

// MARK: - Teacher Dashboard
struct TeacherDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showAddComplaint = false
    @State private var showViewComplaints = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.biitBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        DashboardHeader(
                            greeting: "Welcome back, Sir",
                            name: authVM.currentUserName,
                            role: "Teacher",
                            identifier: ""
                        )

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
                    }
                }
            }
            .navigationTitle("Teacher Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") { authVM.logout() }.foregroundColor(.red)
                }
            }
            .navigationDestination(isPresented: $showAddComplaint) { AddComplaintView() }
            .navigationDestination(isPresented: $showViewComplaints) { ViewComplaintsView() }
        }
    }
}
#Preview {
    TeacherDashboardView()
        .environmentObject({
            let vm = AuthViewModel()
            vm.isLoggedIn = true
            vm.currentRole = "teacher"
            vm.currentUserName = "Dr. Usman Tariq"
            return vm
        }())
}
