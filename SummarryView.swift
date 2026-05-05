import SwiftUI
// MARK: - Summary Tab
struct SummaryTabView: View {
    @ObservedObject var vm: CommitteeDashboardViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading && vm.dashboard == nil {
                    ProgressView("Loading…").padding(40)
                } else {
                    VStack(spacing: 20) {
                        // Header Card
                        if let info = vm.dashboard?.committee_member {
                            HStack(spacing: 14) {
                                Image(systemName: "person.badge.shield.checkmark")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.indigo)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(info.full_name)
                                        .font(.title3.bold())
                                    if let ct = info.committee_type {
                                        Text(ct)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(.indigo.opacity(0.12), in: Capsule())
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            .background(.background, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                        }

                        // Stats Grid
                        if let s = vm.dashboard?.summary {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                CommitteeStatCard(title: "Assigned",     value: s.assigned,    icon: "tray.and.arrow.down",       color: .orange)
                                CommitteeStatCard(title: "In Progress",  value: s.in_progress, icon: "clock.arrow.2.circlepath",  color: .blue)
                                CommitteeStatCard(title: "Resolved",     value: s.resolved,    icon: "checkmark.seal.fill",       color: .green)
                                CommitteeStatCard(title: "Rejected",     value: s.rejected,    icon: "xmark.seal.fill",           color: .red)
                                CommitteeStatCard(title: "Unread",       value: s.unread_notifications, icon: "bell.badge",      color: .purple)
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Committee Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { Task { await vm.loadAll() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable { await vm.loadAll() }
        }
    }
}
#Preview {
    let vm = CommitteeDashboardViewModel()
    
    vm.dashboard = CommitteeDashboard(
        committee_member: CommitteeMemberInfo(
            user_id: 1,
            full_name: "Dr. Ahmed Khan",
            committee_type: "Disciplinary Committee"
        ),
        summary: DashboardSummary(
            assigned: 8,
            in_progress: 5,
            resolved: 12,
            rejected: 3,
            unread_notifications: 2
        )
    )
    vm.isLoading = false
    
    return SummaryTabView(vm: vm)
}
