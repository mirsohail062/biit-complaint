//
//  CommitteeDashboardView.swift
//  BiitComplaintSystem
//

import SwiftUI

// MARK: - Stat Card (Committee-specific)
struct CommitteeStatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.title2.bold())
            }
            Spacer()
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Root Dashboard View
struct CommitteeDashboardView: View {
    @StateObject private var vm = CommitteeDashboardViewModel()
    @State private var selectedTab: DashTab = .summary

    enum DashTab: String, CaseIterable {
        case summary     = "Summary"
        case assigned    = "Assigned"
        case inProgress  = "In Progress"
        case resolved    = "Resolved"
        case rejected    = "Rejected"
        case notifications = "Messages"

        var icon: String {
            switch self {
            case .summary:       return "square.grid.2x2"
            case .assigned:      return "tray.and.arrow.down"
            case .inProgress:    return "clock.arrow.2.circlepath"
            case .resolved:      return "checkmark.seal"
            case .rejected:      return "xmark.seal"
            case .notifications: return "bell"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            SummaryTabView(vm: vm)
                .tabItem { Label("Summary", systemImage: DashTab.summary.icon) }
                .tag(DashTab.summary)

            AssignedTabView(vm: vm)
                .tabItem { Label("Assigned (\(vm.assigned.count))", systemImage: DashTab.assigned.icon) }
                .tag(DashTab.assigned)

            InProgressTabView(vm: vm)
                .tabItem { Label("In Progress (\(vm.inProgress.count))", systemImage: DashTab.inProgress.icon) }
                .tag(DashTab.inProgress)

            ResolvedTabView(vm: vm)
                .tabItem { Label("Resolved", systemImage: DashTab.resolved.icon) }
                .tag(DashTab.resolved)

            RejectedTabView(vm: vm)
                .tabItem { Label("Rejected", systemImage: DashTab.rejected.icon) }
                .tag(DashTab.rejected)

            NotificationsTabView(vm: vm)
                .tabItem { Label("Messages (\(vm.unreadCount))", systemImage: DashTab.notifications.icon) }
                .tag(DashTab.notifications)
        }
        .tint(.indigo)
        .task { await vm.loadAll() }
        .overlay(alignment: .top) {
            if let msg = vm.successMessage {
                ToastView(message: msg, color: .green)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { vm.successMessage = nil }
                        }
                    }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
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
