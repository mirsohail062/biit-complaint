//
//  ViewComplaintsView.swift
//  BiitComplaintSystem
//

import SwiftUI

// MARK: - Tab wrapper
struct ViewComplaintsView: View {
    @StateObject private var vm = ComplaintViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("", selection: $selectedTab) {
                    Text("All").tag(0)
                    Text("In Progress").tag(1)
                    Text("Rejected").tag(2)
                    Text("Resolved").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.biitBg)

                // Content
                switch selectedTab {
                case 0: AllComplaintsTab(vm: vm)
                case 1: ProgressTab(vm: vm)
                case 2: RejectedTab(vm: vm)
                case 3: ResolvedTab(vm: vm)
                default: EmptyView()
                }
            }
            .navigationTitle("My Complaints")
            .task {
                await vm.loadMyComplaints()
                await vm.loadMyProgress()
                await vm.loadMyRejected()
                await vm.loadMyResolved()
            }
        }
    }
}

// MARK: - All Complaints Tab
struct AllComplaintsTab: View {
    @ObservedObject var vm: ComplaintViewModel
    @State private var search = ""

    var filtered: [Complaint] {
        search.isEmpty ? vm.myComplaints :
        vm.myComplaints.filter { $0.location.localizedCaseInsensitiveContains(search) ||
                                  $0.description.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search complaints...", text: $search)
                Text("\(filtered.count)").font(.caption).foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal)

            if filtered.isEmpty {
                EmptyStateView(icon: "doc.text.magnifyingglass", message: "No complaints found")
            } else {
                List(filtered) { c in
                    NavigationLink(destination: ComplaintDetailView(complaint: c)) {
                        ComplaintRowCard(
                            location: c.location,
                            userName: c.user_full_name,
                            date: c.created_at,
                            score: c.genuineness_score
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(Color.biitBg)
            }
        }
        .background(Color.biitBg)
    }
}

// MARK: - Progress Tab
struct ProgressTab: View {
    @ObservedObject var vm: ComplaintViewModel

    var body: some View {
        Group {
            if vm.myProgress.isEmpty {
                EmptyStateView(icon: "clock.badge.checkmark", message: "No complaints in progress")
            } else {
                List(vm.myProgress) { p in
                    NavigationLink(destination: ProgressDetailView(item: p)) {
                        ComplaintRowCard(
                            location: p.complaint.location,
                            userName: p.complaint.user_full_name,
                            date: p.accepted_at
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(Color.biitBg)
            }
        }
    }
}

// MARK: - Rejected Tab
struct RejectedTab: View {
    @ObservedObject var vm: ComplaintViewModel

    var body: some View {
        Group {
            if vm.myRejected.isEmpty {
                EmptyStateView(icon: "xmark.seal", message: "No rejected complaints")
            } else {
                List(vm.myRejected) { r in
                    NavigationLink(destination: RejectedDetailView(item: r)) {
                        ComplaintRowCard(
                            location: r.complaint.location,
                            userName: r.complaint.user_full_name,
                            date: r.rejected_at
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(Color.biitBg)
            }
        }
    }
}

// MARK: - Resolved Tab
struct ResolvedTab: View {
    @ObservedObject var vm: ComplaintViewModel

    var body: some View {
        Group {
            if vm.myResolved.isEmpty {
                EmptyStateView(icon: "checkmark.seal", message: "No resolved complaints")
            } else {
                List(vm.myResolved) { r in
                    NavigationLink(destination: ResolvedDetailView(item: r, vm: vm)) {
                        ComplaintRowCard(
                            location: r.complaint.location,
                            userName: r.complaint.user_full_name,
                            date: r.resolved_at
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(Color.biitBg)
            }
        }
    }
}

// MARK: - Complaint Detail (All)
struct ComplaintDetailView: View {
    let complaint: Complaint

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BIITCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(complaint.location)
                            .font(.title2.bold())
                            .foregroundColor(Color.biitBlue)
                        StatusBadge(status: complaint.status)
                        Label(complaint.category_name ?? "-", systemImage: "folder")
                        Label(complaint.subcategory_name ?? "-", systemImage: "tag")
                        Label(complaint.incident_date.prefix(10).description, systemImage: "calendar")
                    }
                }

                BIITCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Description", systemImage: "text.alignleft").font(.subheadline.bold())
                        Text(complaint.description).foregroundColor(.secondary)
                    }
                }

                if !complaint.involved_students.isEmpty {
                    BIITCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Involved Students", systemImage: "person.3").font(.subheadline.bold())
                            ForEach(complaint.involved_students) { s in
                                HStack {
                                    Text(s.full_name)
                                    Spacer()
                                    Text(s.reg_number).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                if let path = complaint.evidence_path {
                    BIITCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Evidence", systemImage: "paperclip").font(.subheadline.bold())
                            EvidenceView(path: path, type: complaint.evidence_type)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.biitBg)
        .navigationTitle("Complaint Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Progress Detail
struct ProgressDetailView: View {
    let item: ProgressItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BIITCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.complaint.location).font(.title2.bold()).foregroundColor(Color.biitBlue)
                        Label(item.complaint.category_name ?? "-", systemImage: "folder")
                        Label(item.complaint.subcategory_name ?? "-", systemImage: "tag")
                        Label(item.accepted_at.prefix(10).description, systemImage: "calendar")
                    }
                }
                BIITCard {
                    Text(item.complaint.description).foregroundColor(.secondary)
                }
                InvolvedStudentsSection(students: item.complaint.involved_students)
                EvidenceView(path: item.complaint.evidence_path, type: item.complaint.evidence_type)
                    .padding(.horizontal)

                BIITCard {
                    HStack {
                        Image(systemName: "info.circle.fill").foregroundColor(.orange)
                        Text("Thanks for submitting the complaint. We will take action on it.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(Color.biitBg)
        .navigationTitle("In Progress")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Rejected Detail
struct RejectedDetailView: View {
    let item: RejectedItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BIITCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.complaint.location).font(.title2.bold()).foregroundColor(Color.biitBlue)
                        Label(item.complaint.category_name ?? "-", systemImage: "folder")
                        Label(item.complaint.subcategory_name ?? "-", systemImage: "tag")
                    }
                }
                BIITCard {
                    Text(item.complaint.description).foregroundColor(.secondary)
                }
                InvolvedStudentsSection(students: item.complaint.involved_students)
                EvidenceView(path: item.complaint.evidence_path, type: item.complaint.evidence_type)
                    .padding(.horizontal)

                BIITCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Rejection Reason", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red).font(.subheadline.bold())
                        Text(item.reason).foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(Color.biitBg)
        .navigationTitle("Rejected")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Resolved Detail
struct ResolvedDetailView: View {
    let item: ResolvedItem
    @ObservedObject var vm: ComplaintViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BIITCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.complaint.location).font(.title2.bold()).foregroundColor(Color.biitBlue)
                        Label(item.complaint.category_name ?? "-", systemImage: "folder")
                        Label(item.complaint.subcategory_name ?? "-", systemImage: "tag")
                    }
                }
                BIITCard {
                    Text(item.complaint.description).foregroundColor(.secondary)
                }
                InvolvedStudentsSection(students: item.complaint.involved_students)
                EvidenceView(path: item.complaint.evidence_path, type: item.complaint.evidence_type)
                    .padding(.horizontal)

                BIITCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Resolution", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green).font(.subheadline.bold())
                        Text(item.resolution_note).foregroundColor(.secondary)
                    }
                }

                // Feedback
                if item.user_feedback == nil {
                    BIITCard {
                        VStack(spacing: 12) {
                            Text("Has the issue been solved by the committee?")
                                .font(.subheadline.bold())
                                .multilineTextAlignment(.center)
                            HStack(spacing: 16) {
                                Button("✅ Yes") {
                                    Task { await vm.submitFeedback(resolvedId: item.resolved_id, feedback: "yes") }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(10)

                                Button("❌ No") {
                                    Task { await vm.submitFeedback(resolvedId: item.resolved_id, feedback: "no") }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                            }
                        }
                    }
                } else {
                    BIITCard {
                        HStack {
                            Image(systemName: item.user_feedback == "yes" ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(item.user_feedback == "yes" ? .green : .red)
                            Text("Feedback: \(item.user_feedback?.uppercased() ?? "")")
                                .font(.subheadline.bold())
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.biitBg)
        .navigationTitle("Resolved")
        .navigationBarTitleDisplayMode(.inline)
    }
}
// MARK: - Dummy Data
private let dummyComplaint = Complaint(
    complaint_id: 1,
    user_id: 1,
    user_full_name: "Ali Hassan",
    category_id: 1,
    category_name: "Academic",
    subcategory_id: 1,
    subcategory_name: "Grading Issue",
    location: "Room 204, Block A",
    description: "The teacher has not returned the mid-term papers despite multiple requests over the past two weeks.",
    incident_date: "2026-04-01T10:00:00",
    evidence_path: nil,
    evidence_type: nil,
    status: "submitted",
    genuineness_score: 0.87,
    created_at: "2026-04-10T08:30:00",
    involved_students: []
)

private let dummyProgressComplaint = ProgressComplaint(
    location: "Library, Ground Floor",
    category_name: "Facility",
    subcategory_name: "Noise Issue",
    description: "Excessive noise in the library making it impossible to study.",
    evidence_path: nil,
    evidence_type: nil,
    user_full_name: "Sara Ahmed",
    created_at: "2026-04-05T09:00:00",
    involved_students: []
)

private let dummyProgressItem = ProgressItem(
    progress_id: 1,
    complaint_id: 1,
    committee_user_id: 2,
    accepted_at: "2026-04-12T11:00:00",
    overdue_notified: false,
    complaint: dummyProgressComplaint
)

private let dummyRejectedItem = RejectedItem(
    rejected_id: 1,
    complaint_id: 2,
    committee_user_id: 2,
    reason: "Insufficient evidence provided to support the complaint.",
    rejected_at: "2026-04-15T14:00:00",
    admin_asked: false,
    complaint: dummyProgressComplaint
)

private let dummyResolvedItem = ResolvedItem(
    resolved_id: 1,
    complaint_id: 3,
    committee_user_id: 2,
    resolution_note: "The matter was discussed with the concerned teacher and papers were returned.",
    resolved_at: "2026-04-20T16:00:00",
    user_feedback: nil,
    admin_confirmed: false,
    complaint: dummyProgressComplaint
)

// MARK: - Previews

#Preview("View Complaints") {
    ViewComplaintsView()
}

#Preview("Complaint Detail") {
    NavigationStack {
        ComplaintDetailView(complaint: dummyComplaint)
    }
}

#Preview("Progress Detail") {
    NavigationStack {
        ProgressDetailView(item: dummyProgressItem)
    }
}

#Preview("Rejected Detail") {
    NavigationStack {
        RejectedDetailView(item: dummyRejectedItem)
    }
}

#Preview("Resolved Detail - No Feedback") {
    NavigationStack {
        ResolvedDetailView(item: dummyResolvedItem, vm: ComplaintViewModel())
    }
}

#Preview("Resolved Detail - With Feedback") {
    let itemWithFeedback = ResolvedItem(
        resolved_id: 2,
        complaint_id: 4,
        committee_user_id: 2,
        resolution_note: "Issue has been fully resolved.",
        resolved_at: "2026-04-21T10:00:00",
        user_feedback: "yes",
        admin_confirmed: true,
        complaint: dummyProgressComplaint
    )
    NavigationStack {
        ResolvedDetailView(item: itemWithFeedback, vm: ComplaintViewModel())
    }
}
