// Models/AppModels.swift
import Foundation

// MARK: - Auth
struct LoginRequest: Encodable {
    let identifier: String
    let password: String
}

struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let role: String
    let user_id: Int
    let full_name: String
}

// MARK: - User
struct AppUser: Decodable, Identifiable, Hashable {
    let user_id: Int
    let full_name: String
    let identifier: String
    let role: String
    let committee_type: String?
    let is_active: Bool
    let created_at: String

    var id: Int { user_id }
}

struct UserCreate: Encodable {
    let full_name: String
    let identifier: String
    let password: String
    let role: String
    let committee_type: String?
}

// MARK: - Category
// Models/AppModels.swift

// MARK: - Category
struct Subcategory: Decodable, Identifiable, Hashable {
    let subcategory_id: Int
    let name: String
    var id: Int { subcategory_id }
}

struct Category: Decodable, Identifiable, Hashable {
    let category_id: Int
    let name: String
    let subcategories: [Subcategory]
    var id: Int { category_id }
}

// MARK: - Complaint
struct InvolvedStudent: Decodable, Identifiable {
    let id: Int
    let full_name: String
    let reg_number: String
}

struct Complaint: Decodable, Identifiable {
    let complaint_id: Int
    let user_id: Int
    let user_full_name: String?
    let category_id: Int
    let category_name: String?
    let subcategory_id: Int
    let subcategory_name: String?
    let location: String
    let description: String
    let incident_date: String
    let evidence_path: String?
    let evidence_type: String?
    let status: String
    let genuineness_score: Double?
    let created_at: String
    let involved_students: [InvolvedStudent]

    var id: Int { complaint_id }
}

// MARK: - Complaint form helper
struct ComplaintForm {
    var categoryId: Int = 0
    var subcategoryId: Int = 0
    var location: String = ""
    var description: String = ""
    var incidentDate: Date = Date()
    var involvedNames: [String] = []
    var involvedRegs: [String] = []
}

// MARK: - Progress
struct ProgressItem: Decodable, Identifiable {
    let progress_id: Int
    let complaint_id: Int
    let committee_user_id: Int
    let accepted_at: String
    let overdue_notified: Bool
    let complaint: ProgressComplaint

    var id: Int { progress_id }
}

struct ProgressComplaint: Decodable {
    let location: String
    let category_name: String?
    let subcategory_name: String?
    let description: String
    let evidence_path: String?
    let evidence_type: String?
    let user_full_name: String?
    let created_at: String
    let involved_students: [InvolvedStudentSimple]
}

struct InvolvedStudentSimple: Decodable, Identifiable {
    let full_name: String
    let reg_number: String
    var id: String { reg_number }
}

// MARK: - Resolved
struct ResolvedItem: Decodable, Identifiable {
    let resolved_id: Int
    let complaint_id: Int
    let committee_user_id: Int
    let resolution_note: String
    let resolved_at: String
    let user_feedback: String?
    let admin_confirmed: Bool
    let complaint: ProgressComplaint

    var id: Int { resolved_id }
}

// MARK: - Rejected
struct RejectedItem: Decodable, Identifiable {
    let rejected_id: Int
    let complaint_id: Int
    let committee_user_id: Int
    let reason: String
    let rejected_at: String
    let admin_asked: Bool
    let complaint: ProgressComplaint

    var id: Int { rejected_id }
}

// MARK: - Assigned
struct AssignedItem: Decodable, Identifiable {
    let assigned_id: Int
    let complaint_id: Int
    let committee_type: String
    let assigned_at: String
    let complaint: ProgressComplaint

    var id: Int { assigned_id }
}

// MARK: - Notification
struct AppNotification: Decodable, Identifiable {
    let notification_id: Int
    let sender_id: Int
    let sender_name: String?
    let complaint_id: Int?
    let message: String
    let reply: String?
    let is_read: Bool
    let sent_at: String

    var id: Int { notification_id }
}

// MARK: - Analytics
struct Analytics: Decodable {
    let total: Int
    let submitted: Int
    let assigned: Int
    let in_progress: Int
    let resolved: Int
    let rejected: Int
}

// MARK: - Generic detail response
struct DetailResponse: Decodable {
    let detail: String
}

// MARK: - Assign Request
struct AssignRequest: Encodable {
    let complaint_id: Int
    let committee_user_id: Int
    let committee_type: String
}
// Models/CommitteeModels.swift
import Foundation

// MARK: - Dashboard Summary
struct CommitteeDashboard: Decodable {
    let committee_member: CommitteeMemberInfo
    let summary: DashboardSummary
}

struct CommitteeMemberInfo: Decodable {
    let user_id: Int
    let full_name: String
    let committee_type: String?
}

struct DashboardSummary: Decodable {
    let assigned: Int
    let in_progress: Int
    let resolved: Int
    let rejected: Int
    let unread_notifications: Int
}

// MARK: - Assigned Complaint
struct AssignedComplaintItem: Decodable, Identifiable {
    let assigned_id: Int
    let committee_type: String
    let assigned_at: String
    let complaint: CommitteeComplaint
    var id: Int { assigned_id }
}

// MARK: - In-Progress Complaint
struct InProgressItem: Decodable, Identifiable {
    let progress_id: Int
    let accepted_at: String
    let overdue_notified: Bool
    let complaint: CommitteeComplaint
    var id: Int { progress_id }
}

// MARK: - Resolved Complaint
struct CommitteeResolvedItem: Decodable, Identifiable {
    let resolved_id: Int
    let resolution_note: String
    let resolved_at: String
    let user_feedback: String?
    let admin_confirmed: Bool
    let complaint: CommitteeComplaint
    var id: Int { resolved_id }
}

// MARK: - Rejected Complaint
struct CommitteeRejectedItem: Decodable, Identifiable {
    let rejected_id: Int
    let reason: String
    let rejected_at: String
    let admin_asked: Bool
    let complaint: CommitteeComplaint
    var id: Int { rejected_id }
}

// MARK: - Shared Complaint Detail
struct CommitteeComplaint: Decodable {
    let complaint_id: Int
    let user_id: Int
    let user_full_name: String?
    let category_name: String?
    let subcategory_name: String?
    let location: String
    let description: String
    let incident_date: String
    let evidence_path: String?
    let evidence_type: String?
    let status: String
    let genuineness_score: Double?
    let created_at: String
    let involved_students: [InvolvedStudentSimple]
}

// MARK: - Notification
struct CommitteeNotification: Decodable, Identifiable {
    let notification_id: Int
    let sender_name: String?
    let complaint_id: Int?
    let message: String
    let reply: String?
    let is_read: Bool
    let sent_at: String
    var id: Int { notification_id }
}

// MARK: - Request Bodies
struct ResolveRequest: Encodable {
    let complaint_id: Int
    let resolution_note: String
}

struct RejectRequestBody: Encodable {
    let complaint_id: Int
    let reason: String
}

struct ReplyRequestBody: Encodable {
    let reply: String
}
// Models/AppModels.swift (update AppUser to conform to Hashable)
