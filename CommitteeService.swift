// Services/CommitteeService.swift
import Foundation

// NOTE: APIConfig, TokenStore and AppError are defined in APIService.swift.
// This file only adds the committee-specific network calls on top of APIService.shared.

final class CommitteeService {
    static let shared = CommitteeService()
    private init() {}

    // MARK: - Dashboard
    func fetchDashboard() async throws -> CommitteeDashboard {
        try await APIService.shared.request(
            endpoint: "/committee/dashboard",
            responseType: CommitteeDashboard.self
        )
    }

    // MARK: - Assigned
    func fetchAssigned() async throws -> [AssignedComplaintItem] {
        try await APIService.shared.request(
            endpoint: "/committee/assigned",
            responseType: [AssignedComplaintItem].self
        )
    }

    func acceptComplaint(assignedId: Int) async throws -> DetailResponse {
        try await APIService.shared.request(
            endpoint: "/committee/assigned/\(assignedId)/accept",
            method: "POST",
            responseType: DetailResponse.self
        )
    }

    // MARK: - In-Progress
    func fetchInProgress() async throws -> [InProgressItem] {
        try await APIService.shared.request(
            endpoint: "/committee/in-progress",
            responseType: [InProgressItem].self
        )
    }

    func resolveComplaint(progressId: Int, complaintId: Int, note: String) async throws -> DetailResponse {
        // complaint_id is required by ResolvedCreate schema (shared with old resolved router)
        struct Body: Encodable { let complaint_id: Int; let resolution_note: String }
        return try await APIService.shared.request(
            endpoint: "/committee/in-progress/\(progressId)/resolve",
            method: "POST",
            body: Body(complaint_id: complaintId, resolution_note: note),
            responseType: DetailResponse.self
        )
    }

    func rejectComplaint(progressId: Int,complaintId: Int, reason: String) async throws -> DetailResponse {
        // Only reason is needed; committee router reads complaint_id from the Progress row
        struct Body: Encodable { let reason: String }
        return try await APIService.shared.request(
            endpoint: "/committee/in-progress/\(progressId)/reject",
            method: "POST",
            body: Body(reason: reason),
            responseType: DetailResponse.self
        )
    }

    // MARK: - Resolved
    func fetchResolved() async throws -> [CommitteeResolvedItem] {
        try await APIService.shared.request(
            endpoint: "/committee/resolved",
            responseType: [CommitteeResolvedItem].self
        )
    }

    // MARK: - Rejected
    func fetchRejected() async throws -> [CommitteeRejectedItem] {
        try await APIService.shared.request(
            endpoint: "/committee/rejected",
            responseType: [CommitteeRejectedItem].self
        )
    }

    // MARK: - Notifications
    func fetchNotifications() async throws -> [CommitteeNotification] {
        try await APIService.shared.request(
            endpoint: "/committee/notifications",
            responseType: [CommitteeNotification].self
        )
    }

    func replyToNotification(id: Int, reply: String) async throws -> DetailResponse {
        struct Body: Encodable { let reply: String }
        return try await APIService.shared.request(
            endpoint: "/committee/notifications/\(id)/reply",
            method: "POST",
            body: Body(reply: reply),
            responseType: DetailResponse.self
        )
    }

    func markNotificationRead(id: Int) async throws -> DetailResponse {
        try await APIService.shared.request(
            endpoint: "/committee/notifications/\(id)/mark-read",
            method: "POST",
            responseType: DetailResponse.self
        )
    }
}
