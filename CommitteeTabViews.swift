//
//  CommitteeTabViews.swift
//  BiitComplaintSystem
//

import SwiftUI

// MARK: - Assigned Tab
struct AssignedTabView: View {
    @ObservedObject var vm: CommitteeDashboardViewModel

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.assigned.isEmpty {
                    ProgressView("Loading…").frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.assigned.isEmpty {
                    EmptyStateView(icon: "tray", message: "No assigned complaints")
                } else {
                    List(vm.assigned) { item in
                        NavigationLink {
                            AssignedDetailView(item: item, vm: vm)
                        } label: {
                            AssignedRowView(item: item)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Assigned (\(vm.assigned.count))")
            .refreshable { await vm.loadAll() }
        }
    }
}

struct AssignedRowView: View {
    let item: AssignedComplaintItem
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(item.complaint.category_name ?? "—", systemImage: "folder")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
                Spacer()
                Text(item.assigned_at.shortDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(item.complaint.description)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.primary)
            HStack(spacing: 8) {
                Label(item.complaint.user_full_name ?? "Unknown", systemImage: "person")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                ScoreBadge(score: item.complaint.genuineness_score ?? 0)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Assigned Detail View
struct AssignedDetailView: View {
    let item: AssignedComplaintItem
    @ObservedObject var vm: CommitteeDashboardViewModel
    @State private var showConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ComplaintDetailCard(complaint: item.complaint)
                Button {
                    showConfirm = true
                } label: {
                    Label("Accept Complaint", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.indigo, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                        .font(.headline)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Complaint #\(item.complaint.complaint_id)")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Accept this complaint and move it to In Progress?",
                            isPresented: $showConfirm, titleVisibility: .visible) {
            Button("Accept") {
                Task {
                    await vm.accept(item: item)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - In Progress Tab
struct InProgressTabView: View {
    @ObservedObject var vm: CommitteeDashboardViewModel

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.inProgress.isEmpty {
                    ProgressView("Loading…").frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.inProgress.isEmpty {
                    EmptyStateView(icon: "clock", message: "No complaints in progress")
                } else {
                    List(vm.inProgress) { item in
                        NavigationLink {
                            InProgressDetailView(item: item, vm: vm)
                        } label: {
                            InProgressRowView(item: item)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("In Progress (\(vm.inProgress.count))")
            .refreshable { await vm.loadAll() }
        }
    }
}

struct InProgressRowView: View {
    let item: InProgressItem
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(item.complaint.category_name ?? "—", systemImage: "folder")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                Spacer()
                if item.overdue_notified {
                    Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
            Text(item.complaint.description)
                .font(.subheadline)
                .lineLimit(2)
            HStack {
                Label(item.complaint.user_full_name ?? "Unknown", systemImage: "person")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("Since " + item.accepted_at.shortDate)
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - In Progress Detail
struct InProgressDetailView: View {
    let item: InProgressItem
    @ObservedObject var vm: CommitteeDashboardViewModel
    @State private var showResolveSheet = false
    @State private var showRejectSheet  = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ComplaintDetailCard(complaint: item.complaint)

                HStack(spacing: 12) {
                    Button {
                        vm.resolveNote = ""
                        showResolveSheet = true
                    } label: {
                        Label("Resolve", systemImage: "checkmark.seal.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                    Button {
                        vm.rejectReason = ""
                        showRejectSheet = true
                    } label: {
                        Label("Reject", systemImage: "xmark.seal.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Complaint #\(item.complaint.complaint_id)")
        .navigationBarTitleDisplayMode(.inline)
        // Resolve Sheet
        .sheet(isPresented: $showResolveSheet) {
            NavigationStack {
                Form {
                    Section("Resolution Note") {
                        TextEditor(text: $vm.resolveNote)
                            .frame(minHeight: 100)
                    }
                }
                .navigationTitle("Resolve Complaint")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showResolveSheet = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") {
                            showResolveSheet = false
                            Task { await vm.resolve(item: item); dismiss() }
                        }
                        .disabled(vm.resolveNote.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        // Reject Sheet
        .sheet(isPresented: $showRejectSheet) {
            NavigationStack {
                Form {
                    Section("Reason for Rejection") {
                        TextEditor(text: $vm.rejectReason)
                            .frame(minHeight: 100)
                    }
                }
                .navigationTitle("Reject Complaint")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showRejectSheet = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") {
                            showRejectSheet = false
                            Task { await vm.reject(item: item); dismiss() }
                        }
                        .disabled(vm.rejectReason.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Resolved Tab
struct ResolvedTabView: View {
    @ObservedObject var vm: CommitteeDashboardViewModel
    var body: some View {
        NavigationStack {
            Group {
                if vm.resolved.isEmpty {
                    EmptyStateView(icon: "checkmark.seal", message: "No resolved complaints yet")
                } else {
                    List(vm.resolved) { item in
                        NavigationLink {
                            CommitteeResolvedDetailView(item: item)
                        } label: {
                            ResolvedRowView(item: item)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Resolved (\(vm.resolved.count))")
            .refreshable { await vm.loadAll() }
        }
    }
}

struct ResolvedRowView: View {
    let item: CommitteeResolvedItem
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(item.complaint.category_name ?? "—", systemImage: "folder")
                    .font(.caption.weight(.semibold)).foregroundStyle(.green)
                Spacer()
                Text(item.resolved_at.shortDate)
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Text(item.complaint.description).font(.subheadline).lineLimit(2)
            HStack {
                if let fb = item.user_feedback {
                    Label(fb == "yes" ? "Satisfied" : "Not Satisfied",
                          systemImage: fb == "yes" ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .font(.caption)
                    .foregroundStyle(fb == "yes" ? .green : .orange)
                } else {
                    Text("Awaiting feedback").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if item.admin_confirmed {
                    Label("Confirmed", systemImage: "checkmark.circle.fill")
                        .font(.caption2).foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CommitteeResolvedDetailView: View {
    let item: CommitteeResolvedItem
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ComplaintDetailCard(complaint: item.complaint)
                InfoCard(title: "Resolution Note", icon: "doc.text", color: .green) {
                    Text(item.resolution_note).font(.body)
                }
                InfoCard(title: "Status", icon: "info.circle", color: .blue) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Resolved: \(item.resolved_at.shortDate)", systemImage: "calendar")
                                .font(.caption)
                            if let fb = item.user_feedback {
                                Label(fb == "yes" ? "User Satisfied" : "User Not Satisfied",
                                      systemImage: fb == "yes" ? "hand.thumbsup" : "hand.thumbsdown")
                                .font(.caption)
                                .foregroundStyle(fb == "yes" ? .green : .orange)
                            }
                            Label(item.admin_confirmed ? "Admin Confirmed" : "Pending Admin Review",
                                  systemImage: item.admin_confirmed ? "checkmark.shield" : "shield")
                            .font(.caption)
                            .foregroundStyle(item.admin_confirmed ? .green : .secondary)
                        }
                        Spacer()
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Resolved #\(item.complaint.complaint_id)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Rejected Tab
struct RejectedTabView: View {
    @ObservedObject var vm: CommitteeDashboardViewModel
    var body: some View {
        NavigationStack {
            Group {
                if vm.rejected.isEmpty {
                    EmptyStateView(icon: "xmark.seal", message: "No rejected complaints")
                } else {
                    List(vm.rejected) { item in
                        NavigationLink {
                            CommitteeRejectedDetailView(item: item)
                        } label: {
                            RejectedRowView(item: item)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Rejected (\(vm.rejected.count))")
            .refreshable { await vm.loadAll() }
        }
    }
}

struct RejectedRowView: View {
    let item: CommitteeRejectedItem
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(item.complaint.category_name ?? "—", systemImage: "folder")
                    .font(.caption.weight(.semibold)).foregroundStyle(.red)
                Spacer()
                Text(item.rejected_at.shortDate)
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Text(item.complaint.description).font(.subheadline).lineLimit(2)
            Text("Reason: \(item.reason)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

struct CommitteeRejectedDetailView: View {
    let item: CommitteeRejectedItem
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ComplaintDetailCard(complaint: item.complaint)
                InfoCard(title: "Rejection Reason", icon: "xmark.circle", color: .red) {
                    Text(item.reason).font(.body)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Rejected #\(item.complaint.complaint_id)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Complaint Detail Card (Committee-facing)
struct ComplaintDetailCard: View {
    let complaint: CommitteeComplaint

    var body: some View {
        VStack(spacing: 12) {
            // Category + Score header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(complaint.category_name ?? "—")
                        .font(.headline)
                    if let sub = complaint.subcategory_name {
                        Text(sub).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                ScoreBadge(score: complaint.genuineness_score ?? 0)
            }

            Divider()

            // Description
            VStack(alignment: .leading, spacing: 4) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text(complaint.description).font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Location + Date
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Location", systemImage: "mappin").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(complaint.location).font(.caption)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Label("Date", systemImage: "calendar").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(complaint.incident_date.shortDate).font(.caption)
                }
            }

            // Complainant
            HStack {
                Label(complaint.user_full_name ?? "Unknown", systemImage: "person.circle")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                StatusBadge(status: complaint.status)
            }

            // Evidence
            if let epath = complaint.evidence_path, !epath.isEmpty {
                HStack {
                    Image(systemName: complaint.evidence_type == "video" ? "video.fill" : "photo.fill")
                        .foregroundStyle(.indigo)
                    Text("Evidence attached")
                        .font(.caption).foregroundStyle(.indigo)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }

            // Involved Students
            if !complaint.involved_students.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Involved Students", systemImage: "person.2")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    ForEach(complaint.involved_students, id: \.reg_number) { s in
                        HStack {
                            Text(s.full_name).font(.caption)
                            Spacer()
                            Text(s.reg_number).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        .padding(.horizontal)
    }
}

// MARK: - Info Card (Committee-facing)
struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .padding(.horizontal)
    }
}
// MARK: - Dummy Committee Complaints
private let dummyComplaint1 = CommitteeComplaint(
    complaint_id: 1,
    user_id: 1,
    user_full_name: "Ali Hassan",
    category_name: "Academic",
    subcategory_name: "Grading Issue",
    location: "Room 204, Block A",
    description: "The teacher has not returned mid-term papers despite multiple requests over the past two weeks.",
    incident_date: "2026-04-01T10:00:00",
    evidence_path: nil, evidence_type: nil,
    status: "assigned",
    genuineness_score: 0.87,
    created_at: "2026-04-10T08:30:00",
    involved_students: []
)

private let dummyComplaint2 = CommitteeComplaint(
    complaint_id: 2,
    user_id: 2,
    user_full_name: "Sara Ahmed",
    category_name: "Facility",
    subcategory_name: "Noise Issue",
    location: "Library, Ground Floor",
    description: "Excessive noise in the library making it impossible to study during exam week.",
    incident_date: "2026-04-05T09:00:00",
    evidence_path: nil, evidence_type: nil,
    status: "in_progress",
    genuineness_score: 0.72,
    created_at: "2026-04-06T08:00:00",
    involved_students: []
)

private let dummyComplaint3 = CommitteeComplaint(
    complaint_id: 3,
    user_id: 3,
    user_full_name: "Umar Farooq",
    category_name: "Harassment",
    subcategory_name: "Verbal Abuse",
    location: "Cafeteria, Block C",
    description: "A senior student verbally abused me in front of others near the cafeteria.",
    incident_date: "2026-04-08T13:00:00",
    evidence_path: nil, evidence_type: nil,
    status: "resolved",
    genuineness_score: 0.95,
    created_at: "2026-04-09T10:00:00",
    involved_students: []
)

private let dummyComplaint4 = CommitteeComplaint(
    complaint_id: 4,
    user_id: 4,
    user_full_name: "Fatima Malik",
    category_name: "Administrative",
    subcategory_name: "Fee Issue",
    location: "Admin Block, Room 101",
    description: "Fee challan was not issued on time causing issues with bank submission deadline.",
    incident_date: "2026-04-03T11:00:00",
    evidence_path: nil, evidence_type: nil,
    status: "rejected",
    genuineness_score: 0.60,
    created_at: "2026-04-04T09:00:00",
    involved_students: []
)

private let dummyComplaint5 = CommitteeComplaint(
    complaint_id: 5,
    user_id: 5,
    user_full_name: "Zainab Raza",
    category_name: "Infrastructure",
    subcategory_name: "Broken Equipment",
    location: "CS Lab 3, Block B",
    description: "Multiple computers in CS Lab 3 have been non-functional for over a month with no repair action taken.",
    incident_date: "2026-04-10T14:00:00",
    evidence_path: nil, evidence_type: nil,
    status: "assigned",
    genuineness_score: 0.91,
    created_at: "2026-04-11T09:00:00",
    involved_students: [
        InvolvedStudentSimple(full_name: "Bilal Khan", reg_number: "2023-ARID-0042"),
        InvolvedStudentSimple(full_name: "Hina Javed", reg_number: "2023-ARID-0078")
    ]
)

// MARK: - Assigned Items
private let dummyAssigned1 = AssignedComplaintItem(assigned_id: 1, committee_type: "Disciplinary Committee", assigned_at: "2026-04-11T09:00:00", complaint: dummyComplaint1)
private let dummyAssigned2 = AssignedComplaintItem(assigned_id: 2, committee_type: "Academic Committee",      assigned_at: "2026-04-12T10:00:00", complaint: dummyComplaint2)
private let dummyAssigned3 = AssignedComplaintItem(assigned_id: 3, committee_type: "Disciplinary Committee", assigned_at: "2026-04-13T11:00:00", complaint: dummyComplaint3)
private let dummyAssigned4 = AssignedComplaintItem(assigned_id: 4, committee_type: "Administrative Committee",assigned_at: "2026-04-14T08:00:00", complaint: dummyComplaint4)
private let dummyAssigned5 = AssignedComplaintItem(assigned_id: 5, committee_type: "Academic Committee",      assigned_at: "2026-04-15T09:30:00", complaint: dummyComplaint5)

// MARK: - In Progress Items
private let dummyInProgress1 = InProgressItem(progress_id: 1, accepted_at: "2026-04-12T10:00:00", overdue_notified: false, complaint: dummyComplaint1)
private let dummyInProgress2 = InProgressItem(progress_id: 2, accepted_at: "2026-04-13T09:00:00", overdue_notified: true,  complaint: dummyComplaint2)
private let dummyInProgress3 = InProgressItem(progress_id: 3, accepted_at: "2026-04-14T11:00:00", overdue_notified: false, complaint: dummyComplaint3)
private let dummyInProgress4 = InProgressItem(progress_id: 4, accepted_at: "2026-04-15T08:30:00", overdue_notified: true,  complaint: dummyComplaint4)
private let dummyInProgress5 = InProgressItem(progress_id: 5, accepted_at: "2026-04-16T10:00:00", overdue_notified: false, complaint: dummyComplaint5)

// MARK: - Resolved Items
private let dummyResolved1 = CommitteeResolvedItem(resolved_id: 1, resolution_note: "Papers were returned after discussion with the teacher.",                              resolved_at: "2026-04-20T14:00:00", user_feedback: "yes", admin_confirmed: true,  complaint: dummyComplaint1)
private let dummyResolved2 = CommitteeResolvedItem(resolved_id: 2, resolution_note: "Library management installed noise barriers and set quiet hours.",                    resolved_at: "2026-04-21T11:00:00", user_feedback: "yes", admin_confirmed: false, complaint: dummyComplaint2)
private let dummyResolved3 = CommitteeResolvedItem(resolved_id: 3, resolution_note: "Senior student was given a formal warning and asked to apologize.",                   resolved_at: "2026-04-22T15:00:00", user_feedback: nil,   admin_confirmed: false, complaint: dummyComplaint3)
private let dummyResolved4 = CommitteeResolvedItem(resolved_id: 4, resolution_note: "Finance department issued the challan and extended the bank submission deadline.",    resolved_at: "2026-04-23T09:00:00", user_feedback: "no",  admin_confirmed: true,  complaint: dummyComplaint4)
private let dummyResolved5 = CommitteeResolvedItem(resolved_id: 5, resolution_note: "IT department repaired all faulty computers and added 5 new machines to the lab.",   resolved_at: "2026-04-24T13:00:00", user_feedback: "yes", admin_confirmed: true,  complaint: dummyComplaint5)

// MARK: - Rejected Items
private let dummyRejected1 = CommitteeRejectedItem(rejected_id: 1, reason: "Insufficient evidence provided. Please resubmit with proper documentation.",        rejected_at: "2026-04-15T11:00:00", admin_asked: false, complaint: dummyComplaint1)
private let dummyRejected2 = CommitteeRejectedItem(rejected_id: 2, reason: "Complaint was filed against the wrong department. Please contact facilities directly.", rejected_at: "2026-04-16T10:00:00", admin_asked: true,  complaint: dummyComplaint2)
private let dummyRejected3 = CommitteeRejectedItem(rejected_id: 3, reason: "The incident could not be verified by any witnesses present at the location.",        rejected_at: "2026-04-17T14:00:00", admin_asked: false, complaint: dummyComplaint3)
private let dummyRejected4 = CommitteeRejectedItem(rejected_id: 4, reason: "This is a known policy issue currently being addressed at the administrative level.",  rejected_at: "2026-04-18T09:30:00", admin_asked: true,  complaint: dummyComplaint4)
private let dummyRejected5 = CommitteeRejectedItem(rejected_id: 5, reason: "Duplicate complaint. A similar complaint was already submitted and is being handled.", rejected_at: "2026-04-19T11:00:00", admin_asked: false, complaint: dummyComplaint5)

// MARK: - Previews
#Preview("Assigned Tab") {
    let vm = CommitteeDashboardViewModel()
    vm.assigned = [dummyAssigned1, dummyAssigned2, dummyAssigned3, dummyAssigned4, dummyAssigned5]
    return AssignedTabView(vm: vm)
}

#Preview("Assigned Detail") {
    let vm = CommitteeDashboardViewModel()
    return NavigationStack {
        AssignedDetailView(item: dummyAssigned5, vm: vm)
    }
}

#Preview("In Progress Tab") {
    let vm = CommitteeDashboardViewModel()
    vm.inProgress = [dummyInProgress1, dummyInProgress2, dummyInProgress3, dummyInProgress4, dummyInProgress5]
    return InProgressTabView(vm: vm)
}

#Preview("In Progress Detail - Overdue") {
    let vm = CommitteeDashboardViewModel()
    return NavigationStack {
        InProgressDetailView(item: dummyInProgress2, vm: vm)
    }
}

#Preview("Resolved Tab") {
    let vm = CommitteeDashboardViewModel()
    vm.resolved = [dummyResolved1, dummyResolved2, dummyResolved3, dummyResolved4, dummyResolved5]
    return ResolvedTabView(vm: vm)
}

#Preview("Resolved Detail - Confirmed") {
    NavigationStack {
        CommitteeResolvedDetailView(item: dummyResolved1)
    }
}

#Preview("Resolved Detail - No Feedback") {
    NavigationStack {
        CommitteeResolvedDetailView(item: dummyResolved3)
    }
}

#Preview("Rejected Tab") {
    let vm = CommitteeDashboardViewModel()
    vm.rejected = [dummyRejected1, dummyRejected2, dummyRejected3, dummyRejected4, dummyRejected5]
    return RejectedTabView(vm: vm)
}

#Preview("Rejected Detail") {
    NavigationStack {
        CommitteeRejectedDetailView(item: dummyRejected5)
    }
}

#Preview("Complaint Detail Card - With Students") {
    ScrollView {
        ComplaintDetailCard(complaint: dummyComplaint5)
            .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
