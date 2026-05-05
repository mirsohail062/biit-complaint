import SwiftUI

// MARK: - Admin Stat Card
struct AdminStatCard: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

struct AdminDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm: AdminViewModel

    // runtime init
    init() { _vm = StateObject(wrappedValue: AdminViewModel()) }

    // preview init
    init(previewVM: AdminViewModel) {
        _vm = StateObject(wrappedValue: previewVM)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.biitBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        DashboardHeader(greeting: "Welcome back to", name: "Admin Dashboard",
                                        role: "Administrator", identifier: "")

                        VStack(spacing: 16) {
                            if let a = vm.analytics {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    AdminStatCard(title: "Total",       value: a.total,       color: .biitBlue)
                                    AdminStatCard(title: "In Progress", value: a.in_progress, color: .orange)
                                    AdminStatCard(title: "Resolved",    value: a.resolved,    color: .green)
                                    AdminStatCard(title: "Rejected",    value: a.rejected,    color: .red)
                                    AdminStatCard(title: "Submitted",   value: a.submitted,   color: .gray)
                                    AdminStatCard(title: "Assigned",    value: a.assigned,    color: .purple)
                                }
                            }

                            SectionHeader(title: "Complaint Management")

                            NavigationLink(destination: ViewAllComplaintsAdmin(vm: vm)) {
                                AdminMenuCard(title: "View Complaints", subtitle: "Unassigned complaints", icon: "tray.full.fill", color: .biitBlue)
                            }

                            NavigationLink(destination: ComplaintStatusAdmin(vm: vm)) {
                                AdminMenuCard(title: "Complaint Status", subtitle: "Progress · Resolved · Rejected", icon: "chart.bar.fill", color: .orange)
                            }

                            SectionHeader(title: "User Management")

                            NavigationLink(destination: ManageUsersAdmin(vm: vm, role: "student")) {
                                AdminMenuCard(title: "View Registered Students", subtitle: "Add · Remove students", icon: "graduationcap.fill", color: .green)
                            }

                            NavigationLink(destination: ManageUsersAdmin(vm: vm, role: "teacher")) {
                                AdminMenuCard(title: "View Registered Teachers", subtitle: "Add · Remove teachers", icon: "person.fill", color: .purple)
                            }

                            NavigationLink(destination: ManageUsersAdmin(vm: vm, role: "committee")) {
                                AdminMenuCard(title: "View Committee Members", subtitle: "Add · Remove committee", icon: "person.3.fill", color: .red)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") { authVM.logout() }.foregroundColor(.red)
                }
            }
            .task { await vm.loadAnalytics() }
        }
    }
}

// MARK: - Admin Menu Card
struct AdminMenuCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).frame(width: 50, height: 50)
                Image(systemName: icon).font(.title3).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundColor(.primary)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - View All Unassigned Complaints (Admin)
struct ViewAllComplaintsAdmin: View {
    @ObservedObject var vm: AdminViewModel
    @State private var search = ""

    var filtered: [Complaint] {
        search.isEmpty ? vm.unassigned :
        vm.unassigned.filter { $0.location.localizedCaseInsensitiveContains(search) ||
                                ($0.category_name ?? "").localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        ZStack {
            Color.biitBg.ignoresSafeArea()
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search by keyword, category, date...", text: $search)
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)

                List(filtered) { c in
                    NavigationLink(destination: AdminComplaintDetail(complaint: c, vm: vm)) {
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
            }
        }
        .navigationTitle("View Complaints")
        .task { await vm.loadUnassigned() }
    }
}

// MARK: - Admin Complaint Detail + Assign
struct AdminComplaintDetail: View {
    let complaint: Complaint
    @ObservedObject var vm: AdminViewModel
    @State private var selectedCommitteeUser: AppUser?
    @State private var selectedType = "Disciplinary Committee"

    let committeeTypes = ["Disciplinary Committee", "Academic Committee",
                          "Administrative Committee", "Others"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BIITCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(complaint.location).font(.title2.bold()).foregroundColor(.biitBlue)
                        Label(complaint.category_name ?? "-", systemImage: "folder")
                        Label(complaint.subcategory_name ?? "-", systemImage: "tag")
                        Label(complaint.user_full_name ?? "-", systemImage: "person")
                        Label(complaint.created_at.prefix(10).description, systemImage: "calendar")
                        if let score = complaint.genuineness_score {
                            HStack { Text("Genuineness Score:"); ScoreBadge(score: score) }
                        }
                    }
                }
                BIITCard {
                    Text(complaint.description).foregroundColor(.secondary)
                }
                if !complaint.involved_students.isEmpty {
                    BIITCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Involved Students", systemImage: "person.3").font(.subheadline.bold())
                            ForEach(complaint.involved_students) { s in
                                HStack { Text(s.full_name); Spacer(); Text(s.reg_number).font(.caption).foregroundColor(.secondary) }
                            }
                        }
                    }
                }
                EvidenceView(path: complaint.evidence_path, type: complaint.evidence_type).padding(.horizontal)

                ErrorBanner(message: vm.errorMessage)
                if !vm.successMessage.isEmpty {
                    Text(vm.successMessage).foregroundColor(.green).padding(.horizontal)
                }

                BIITCard {
                    VStack(spacing: 12) {
                        Picker("Committee Type", selection: $selectedType) {
                            ForEach(committeeTypes, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)

                        Picker("Committee Member", selection: $selectedCommitteeUser) {
                            Text("Select Member").tag(nil as AppUser?)
                            ForEach(vm.committee.filter { $0.committee_type == selectedType || $0.committee_type == nil }) { u in
                                Text(u.full_name).tag(u as AppUser?)
                            }
                        }
                        .pickerStyle(.menu)

                        PrimaryButton(title: "Assign Complaint", icon: "arrow.right.circle.fill") {
                            guard let member = selectedCommitteeUser else { return }
                            Task {
                                await vm.assignComplaint(
                                    complaintId: complaint.complaint_id,
                                    committeeUserId: member.user_id,
                                    committeeType: selectedType
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.biitBg)
        .navigationTitle("Complaint Detail")
        .task { await vm.loadCommittee() }
    }
}

// MARK: - Complaint Status (In Progress / Resolved / Rejected)
struct ComplaintStatusAdmin: View {
    @ObservedObject var vm: AdminViewModel
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text("In Progress").tag(0)
                Text("Resolved").tag(1)
                Text("Rejected").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            switch tab {
            case 0: AdminProgressList(vm: vm)
            case 1: AdminResolvedList(vm: vm)
            case 2: AdminRejectedList(vm: vm)
            default: EmptyView()
            }
        }
        .navigationTitle("Complaint Status")
        .task {
            await vm.loadProgress()
            await vm.loadResolved()
            await vm.loadRejected()
        }
    }
}

struct AdminProgressList: View {
    @ObservedObject var vm: AdminViewModel
    var body: some View {
        List(vm.allProgress) { p in
            NavigationLink(destination: AdminProgressDetail(item: p, vm: vm)) {
                ComplaintRowCard(
                    location: p.complaint.location,
                    userName: p.complaint.user_full_name,
                    date: p.accepted_at
                )
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }.listStyle(.plain).background(Color.biitBg)
    }
}

struct AdminProgressDetail: View {
    let item: ProgressItem
    @ObservedObject var vm: AdminViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BIITCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.complaint.location).font(.title2.bold()).foregroundColor(.biitBlue)
                        Label(item.complaint.category_name ?? "-", systemImage: "folder")
                        Label(item.complaint.subcategory_name ?? "-", systemImage: "tag")
                        Label(item.complaint.user_full_name ?? "-", systemImage: "person")
                        Label(item.accepted_at.prefix(10).description, systemImage: "calendar")
                        if item.overdue_notified {
                            Label("Overdue — reminder sent to committee", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                BIITCard { Text(item.complaint.description).foregroundColor(.secondary) }
                InvolvedStudentsSection(students: item.complaint.involved_students)
                EvidenceView(path: item.complaint.evidence_path, type: item.complaint.evidence_type).padding(.horizontal)

                PrimaryButton(title: "Send Overdue Reminder", icon: "bell.badge.fill") { }
                .padding(.horizontal)
            }
            .padding()
        }
        .background(Color.biitBg)
        .navigationTitle("In Progress Detail")
    }
}

struct AdminResolvedList: View {
    @ObservedObject var vm: AdminViewModel
    var body: some View {
        List(vm.allResolved) { r in
            NavigationLink(destination: AdminResolvedDetail(item: r, vm: vm)) {
                ComplaintRowCard(
                    location: r.complaint.location,
                    userName: r.complaint.user_full_name,
                    date: r.resolved_at
                )
            }
            .listRowBackground(Color.clear).listRowSeparator(.hidden)
        }.listStyle(.plain).background(Color.biitBg)
    }
}

struct AdminResolvedDetail: View {
    let item: ResolvedItem
    @ObservedObject var vm: AdminViewModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BIITCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.complaint.location).font(.title2.bold()).foregroundColor(.biitBlue)
                        Label(item.complaint.category_name ?? "-", systemImage: "folder")
                        Label(item.complaint.subcategory_name ?? "-", systemImage: "tag")
                        Label(item.complaint.user_full_name ?? "-", systemImage: "person")
                        if let fb = item.user_feedback {
                            HStack {
                                Image(systemName: fb == "yes" ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(fb == "yes" ? .green : .red)
                                Text("User feedback: \(fb.uppercased())").font(.subheadline)
                            }
                        }
                    }
                }
                BIITCard { Text(item.complaint.description).foregroundColor(.secondary) }
                EvidenceView(path: item.complaint.evidence_path, type: item.complaint.evidence_type).padding(.horizontal)

                HStack(spacing: 12) {
                    Button("✅ Admin Confirm") {
                        Task { await vm.adminConfirmResolved(resolvedId: item.resolved_id) }
                    }
                    .frame(maxWidth: .infinity).padding(12)
                    .background(Color.green.opacity(0.1)).foregroundColor(.green).cornerRadius(10)

                    Button("🗑 Delete") {
                        Task { await vm.adminConfirmResolved(resolvedId: item.resolved_id, delete: true) }
                    }
                    .frame(maxWidth: .infinity).padding(12)
                    .background(Color.red.opacity(0.1)).foregroundColor(.red).cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .background(Color.biitBg)
        .navigationTitle("Resolved Detail")
    }
}

struct AdminRejectedList: View {
    @ObservedObject var vm: AdminViewModel
    var body: some View {
        List(vm.allRejected) { r in
            NavigationLink(destination: AdminRejectedDetail(item: r, vm: vm)) {
                ComplaintRowCard(
                    location: r.complaint.location,
                    userName: r.complaint.user_full_name,
                    date: r.rejected_at
                )
            }
            .listRowBackground(Color.clear).listRowSeparator(.hidden)
        }.listStyle(.plain).background(Color.biitBg)
    }
}

struct AdminRejectedDetail: View {
    let item: RejectedItem
    @ObservedObject var vm: AdminViewModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BIITCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.complaint.location).font(.title2.bold()).foregroundColor(.biitBlue)
                        Label(item.complaint.category_name ?? "-", systemImage: "folder")
                        Label(item.complaint.user_full_name ?? "-", systemImage: "person")
                    }
                }
                BIITCard {
                    VStack(alignment: .leading) {
                        Label("Rejection Reason", systemImage: "xmark.circle").foregroundColor(.red).font(.subheadline.bold())
                        Text(item.reason).foregroundColor(.secondary)
                    }
                }
                EvidenceView(path: item.complaint.evidence_path, type: item.complaint.evidence_type).padding(.horizontal)

                Button("🗑 Delete Rejected Complaint") {
                    Task { await vm.deleteRejected(item.rejected_id) }
                }
                .frame(maxWidth: .infinity).padding(14)
                .background(Color.red.opacity(0.1)).foregroundColor(.red).cornerRadius(12)
                .padding(.horizontal)
            }
            .padding()
        }
        .background(Color.biitBg)
        .navigationTitle("Rejected Detail")
    }
}

// MARK: - Manage Users (Student / Teacher / Committee)
struct ManageUsersAdmin: View {
    @ObservedObject var vm: AdminViewModel
    let role: String
    @State private var showRegister = false
    @State private var editMode = false

    var users: [AppUser] {
        switch role {
        case "student":   return vm.students
        case "teacher":   return vm.teachers
        case "committee": return vm.committee
        default:          return []
        }
    }

    var body: some View {
        ZStack {
            Color.biitBg.ignoresSafeArea()
            VStack {
                List {
                    ForEach(users) { u in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(u.full_name).font(.headline)
                                Text(u.identifier).font(.caption).foregroundColor(.secondary)
                                if let ct = u.committee_type { Text(ct).font(.caption2).foregroundColor(.biitBlue) }
                            }
                            Spacer()
                            if editMode {
                                Button {
                                    Task {
                                        switch role {
                                        case "student":   await vm.deleteStudent(u.user_id)
                                        case "teacher":   await vm.deleteTeacher(u.user_id)
                                        case "committee": await vm.deleteCommittee(u.user_id)
                                        default: break
                                        }
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.red).font(.title2)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.white)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(role.capitalized + "s")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(editMode ? "Done" : "Remove") { editMode.toggle() }
                    .foregroundColor(editMode ? .biitBlue : .red)
                Button("Register") { showRegister = true }
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterUserSheet(vm: vm, role: role)
        }
        .task {
            switch role {
            case "student":   await vm.loadStudents()
            case "teacher":   await vm.loadTeachers()
            case "committee": await vm.loadCommittee()
            default: break
            }
        }
    }
}

struct RegisterUserSheet: View {
    @ObservedObject var vm: AdminViewModel
    let role: String
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var identifier = ""
    @State private var password = ""
    @State private var committeeType = "Disciplinary Committee"

    let committeeTypes = ["Disciplinary Committee", "Academic Committee",
                          "Administrative Committee", "Others"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Details") {
                    TextField("Full Name", text: $fullName)
                    TextField(role == "student" ? "20XX-ARID-XXXX" : "Employee ID", text: $identifier)
                        .textInputAutocapitalization(.characters)
                    SecureField("Password", text: $password)
                }
                if role == "committee" {
                    Section("Committee Assignment") {
                        Picker("Committee Type", selection: $committeeType) {
                            ForEach(committeeTypes, id: \.self) { Text($0) }
                        }
                    }
                }

                ErrorBanner(message: vm.errorMessage)

                Section {
                    Button("Register") {
                        Task {
                            let user = UserCreate(
                                full_name: fullName,
                                identifier: identifier,
                                password: password,
                                role: role,
                                committee_type: role == "committee" ? committeeType : nil
                            )
                            await vm.registerUser(user: user)
                            if vm.errorMessage.isEmpty { dismiss() }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.biitBlue)
                }
            }
            .navigationTitle("Register \(role.capitalized)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

// MARK: - Dummy Data
private let dummyAdminComplaint1 = Complaint(
    complaint_id: 1, user_id: 1, user_full_name: "Ali Hassan",
    category_id: 1, category_name: "Academic", subcategory_id: 1, subcategory_name: "Grading Issue",
    location: "Room 204, Block A",
    description: "Teacher has not returned mid-term papers despite multiple requests over two weeks.",
    incident_date: "2026-04-01T10:00:00", evidence_path: nil, evidence_type: nil,
    status: "submitted", genuineness_score: 0.87, created_at: "2026-04-10T08:30:00", involved_students: []
)
private let dummyAdminComplaint2 = Complaint(
    complaint_id: 2, user_id: 2, user_full_name: "Sara Ahmed",
    category_id: 2, category_name: "Facility", subcategory_id: 3, subcategory_name: "Noise Issue",
    location: "Library, Ground Floor",
    description: "Excessive noise in the library making it impossible to study during exam week.",
    incident_date: "2026-04-05T09:00:00", evidence_path: nil, evidence_type: nil,
    status: "submitted", genuineness_score: 0.72, created_at: "2026-04-06T10:00:00", involved_students: []
)
private let dummyAdminComplaint3 = Complaint(
    complaint_id: 3, user_id: 3, user_full_name: "Umar Farooq",
    category_id: 3, category_name: "Harassment", subcategory_id: 5, subcategory_name: "Verbal Abuse",
    location: "Cafeteria, Block C",
    description: "A senior student verbally abused me in front of others near the cafeteria.",
    incident_date: "2026-04-08T13:00:00", evidence_path: nil, evidence_type: nil,
    status: "submitted", genuineness_score: 0.95, created_at: "2026-04-09T11:00:00", involved_students: []
)
private let dummyAdminComplaint4 = Complaint(
    complaint_id: 4, user_id: 4, user_full_name: "Fatima Malik",
    category_id: 4, category_name: "Administrative", subcategory_id: 6, subcategory_name: "Fee Issue",
    location: "Admin Block, Room 101",
    description: "Fee challan was not issued on time causing issues with bank submission deadline.",
    incident_date: "2026-04-03T11:00:00", evidence_path: nil, evidence_type: nil,
    status: "submitted", genuineness_score: 0.60, created_at: "2026-04-04T09:00:00", involved_students: []
)
private let dummyAdminComplaint5 = Complaint(
    complaint_id: 5, user_id: 5, user_full_name: "Zainab Raza",
    category_id: 5, category_name: "Infrastructure", subcategory_id: 7, subcategory_name: "Broken Equipment",
    location: "CS Lab 3, Block B",
    description: "Multiple computers in CS Lab 3 have been non-functional for over a month.",
    incident_date: "2026-04-10T14:00:00", evidence_path: nil, evidence_type: nil,
    status: "submitted", genuineness_score: 0.91, created_at: "2026-04-11T09:00:00",
    involved_students: [
        InvolvedStudent(id: 1, full_name: "Bilal Khan", reg_number: "2023-ARID-0042"),
        InvolvedStudent(id: 2, full_name: "Hina Javed", reg_number: "2023-ARID-0078")
    ]
)

private let dummyPC1 = ProgressComplaint(location: "Room 204, Block A",    category_name: "Academic",        subcategory_name: "Grading Issue",    description: "Teacher has not returned mid-term papers.",              evidence_path: nil, evidence_type: nil, user_full_name: "Ali Hassan",    created_at: "2026-04-10T08:30:00", involved_students: [])
private let dummyPC2 = ProgressComplaint(location: "Library, Ground Floor",category_name: "Facility",        subcategory_name: "Noise Issue",       description: "Excessive noise during exam week.",                      evidence_path: nil, evidence_type: nil, user_full_name: "Sara Ahmed",    created_at: "2026-04-06T10:00:00", involved_students: [])
private let dummyPC3 = ProgressComplaint(location: "Cafeteria, Block C",   category_name: "Harassment",      subcategory_name: "Verbal Abuse",      description: "A senior student verbally abused me.",                   evidence_path: nil, evidence_type: nil, user_full_name: "Umar Farooq",   created_at: "2026-04-09T11:00:00", involved_students: [])
private let dummyPC4 = ProgressComplaint(location: "Admin Block, Room 101",category_name: "Administrative",  subcategory_name: "Fee Issue",         description: "Fee challan was not issued on time.",                    evidence_path: nil, evidence_type: nil, user_full_name: "Fatima Malik",  created_at: "2026-04-04T09:00:00", involved_students: [])
private let dummyPC5 = ProgressComplaint(location: "CS Lab 3, Block B",    category_name: "Infrastructure",  subcategory_name: "Broken Equipment",  description: "Multiple computers non-functional for over a month.",    evidence_path: nil, evidence_type: nil, user_full_name: "Zainab Raza",   created_at: "2026-04-11T09:00:00", involved_students: [])

private let dummyProgressItems: [ProgressItem] = [
    ProgressItem(progress_id: 1, complaint_id: 1, committee_user_id: 10, accepted_at: "2026-04-12T10:00:00", overdue_notified: false, complaint: dummyPC1),
    ProgressItem(progress_id: 2, complaint_id: 2, committee_user_id: 10, accepted_at: "2026-04-13T09:00:00", overdue_notified: true,  complaint: dummyPC2),
    ProgressItem(progress_id: 3, complaint_id: 3, committee_user_id: 11, accepted_at: "2026-04-14T11:00:00", overdue_notified: false, complaint: dummyPC3),
    ProgressItem(progress_id: 4, complaint_id: 4, committee_user_id: 11, accepted_at: "2026-04-15T08:30:00", overdue_notified: true,  complaint: dummyPC4),
    ProgressItem(progress_id: 5, complaint_id: 5, committee_user_id: 12, accepted_at: "2026-04-16T10:00:00", overdue_notified: false, complaint: dummyPC5)
]

private let dummyResolvedItems: [ResolvedItem] = [
    ResolvedItem(resolved_id: 1, complaint_id: 1, committee_user_id: 10, resolution_note: "Papers returned after discussion with teacher.",                      resolved_at: "2026-04-20T14:00:00", user_feedback: "yes", admin_confirmed: false, complaint: dummyPC1),
    ResolvedItem(resolved_id: 2, complaint_id: 2, committee_user_id: 10, resolution_note: "Library installed noise barriers and set quiet hours.",               resolved_at: "2026-04-21T11:00:00", user_feedback: "yes", admin_confirmed: true,  complaint: dummyPC2),
    ResolvedItem(resolved_id: 3, complaint_id: 3, committee_user_id: 11, resolution_note: "Senior student given a formal warning and asked to apologize.",       resolved_at: "2026-04-22T15:00:00", user_feedback: nil,   admin_confirmed: false, complaint: dummyPC3),
    ResolvedItem(resolved_id: 4, complaint_id: 4, committee_user_id: 11, resolution_note: "Finance extended the bank submission deadline by one week.",          resolved_at: "2026-04-23T09:00:00", user_feedback: "no",  admin_confirmed: false, complaint: dummyPC4),
    ResolvedItem(resolved_id: 5, complaint_id: 5, committee_user_id: 12, resolution_note: "IT repaired all faulty computers and added 5 new machines to lab.",  resolved_at: "2026-04-24T13:00:00", user_feedback: "yes", admin_confirmed: true,  complaint: dummyPC5)
]

private let dummyRejectedItems: [RejectedItem] = [
    RejectedItem(rejected_id: 1, complaint_id: 1, committee_user_id: 10, reason: "Insufficient evidence. Please resubmit with documentation.",         rejected_at: "2026-04-15T11:00:00", admin_asked: false, complaint: dummyPC1),
    RejectedItem(rejected_id: 2, complaint_id: 2, committee_user_id: 10, reason: "Filed against wrong department. Contact facilities directly.",        rejected_at: "2026-04-16T10:00:00", admin_asked: true,  complaint: dummyPC2),
    RejectedItem(rejected_id: 3, complaint_id: 3, committee_user_id: 11, reason: "Incident could not be verified by any witnesses at the location.",    rejected_at: "2026-04-17T14:00:00", admin_asked: false, complaint: dummyPC3),
    RejectedItem(rejected_id: 4, complaint_id: 4, committee_user_id: 11, reason: "Policy issue being addressed at the administrative level already.",   rejected_at: "2026-04-18T09:30:00", admin_asked: true,  complaint: dummyPC4),
    RejectedItem(rejected_id: 5, complaint_id: 5, committee_user_id: 12, reason: "Duplicate complaint. A similar one is already being handled.",        rejected_at: "2026-04-19T11:00:00", admin_asked: false, complaint: dummyPC5)
]

private let dummyStudents: [AppUser] = [
    AppUser(user_id: 1, full_name: "Ali Hassan",    identifier: "2023-ARID-0011", role: "student", committee_type: nil, is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 2, full_name: "Sara Ahmed",    identifier: "2023-ARID-0022", role: "student", committee_type: nil, is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 3, full_name: "Umar Farooq",   identifier: "2023-ARID-0033", role: "student", committee_type: nil, is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 4, full_name: "Fatima Malik",  identifier: "2023-ARID-0044", role: "student", committee_type: nil, is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 5, full_name: "Zainab Raza",   identifier: "2023-ARID-0055", role: "student", committee_type: nil, is_active: true, created_at: "2026-01-01")
]

private let dummyTeachers: [AppUser] = [
    AppUser(user_id: 6,  full_name: "Dr. Usman Tariq",     identifier: "EMP-001", role: "teacher", committee_type: nil, is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 7,  full_name: "Prof. Nadia Khan",     identifier: "EMP-002", role: "teacher", committee_type: nil, is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 8,  full_name: "Dr. Imran Butt",       identifier: "EMP-003", role: "teacher", committee_type: nil, is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 9,  full_name: "Ms. Ayesha Siddiqi",   identifier: "EMP-004", role: "teacher", committee_type: nil, is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 10, full_name: "Mr. Kamran Akhtar",    identifier: "EMP-005", role: "teacher", committee_type: nil, is_active: true, created_at: "2026-01-01")
]

private let dummyCommittee: [AppUser] = [
    AppUser(user_id: 11, full_name: "Dr. Ahmed Khan",       identifier: "COM-001", role: "committee", committee_type: "Disciplinary Committee",  is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 12, full_name: "Ms. Hina Javed",       identifier: "COM-002", role: "committee", committee_type: "Academic Committee",       is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 13, full_name: "Mr. Bilal Cheema",     identifier: "COM-003", role: "committee", committee_type: "Administrative Committee", is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 14, full_name: "Dr. Sana Mirza",       identifier: "COM-004", role: "committee", committee_type: "Disciplinary Committee",   is_active: true, created_at: "2026-01-01"),
    AppUser(user_id: 15, full_name: "Prof. Tariq Mehmood",  identifier: "COM-005", role: "committee", committee_type: "Academic Committee",       is_active: true, created_at: "2026-01-01")
]

// MARK: - Previews
#Preview("Admin Dashboard") {
    let vm = AdminViewModel()
    vm.analytics = Analytics(total: 42, submitted: 5, assigned: 2, in_progress: 10, resolved: 20, rejected: 5)
    return AdminDashboardView(previewVM: vm)
        .environmentObject({
            let auth = AuthViewModel()
            auth.isLoggedIn = true
            auth.currentRole = "admin"
            auth.currentUserName = "Admin User"
            return auth
        }())
}

#Preview("View All Complaints") {
    let vm = AdminViewModel()
    vm.unassigned = [dummyAdminComplaint1, dummyAdminComplaint2, dummyAdminComplaint3, dummyAdminComplaint4, dummyAdminComplaint5]
    return NavigationStack { ViewAllComplaintsAdmin(vm: vm) }
}

#Preview("Complaint Detail + Assign") {
    let vm = AdminViewModel()
    vm.committee = dummyCommittee
    return NavigationStack { AdminComplaintDetail(complaint: dummyAdminComplaint5, vm: vm) }
}

#Preview("Complaint Status") {
    let vm = AdminViewModel()
    vm.allProgress = dummyProgressItems
    vm.allResolved = dummyResolvedItems
    vm.allRejected = dummyRejectedItems
    return NavigationStack { ComplaintStatusAdmin(vm: vm) }
}

#Preview("Progress Detail - Overdue") {
    let vm = AdminViewModel()
    return NavigationStack { AdminProgressDetail(item: dummyProgressItems[1], vm: vm) }
}

#Preview("Resolved Detail") {
    let vm = AdminViewModel()
    return NavigationStack { AdminResolvedDetail(item: dummyResolvedItems[0], vm: vm) }
}

#Preview("Rejected Detail") {
    let vm = AdminViewModel()
    return NavigationStack { AdminRejectedDetail(item: dummyRejectedItems[0], vm: vm) }
}

#Preview("Manage Students") {
    let vm = AdminViewModel()
    vm.students = dummyStudents
    return NavigationStack { ManageUsersAdmin(vm: vm, role: "student") }
}

#Preview("Manage Teachers") {
    let vm = AdminViewModel()
    vm.teachers = dummyTeachers
    return NavigationStack { ManageUsersAdmin(vm: vm, role: "teacher") }
}

#Preview("Manage Committee") {
    let vm = AdminViewModel()
    vm.committee = dummyCommittee
    return NavigationStack { ManageUsersAdmin(vm: vm, role: "committee") }
}

#Preview("Register Student Sheet") {
    RegisterUserSheet(vm: AdminViewModel(), role: "student")
}

#Preview("Register Committee Sheet") {
    RegisterUserSheet(vm: AdminViewModel(), role: "committee")
}
