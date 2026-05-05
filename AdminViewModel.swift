// ViewModels/AdminViewModel.swift
import Foundation
import Combine
import SwiftUI

@MainActor
final class AdminViewModel: ObservableObject {
    @Published var unassigned:    [Complaint]    = []
    @Published var allProgress:   [ProgressItem] = []
    @Published var allResolved:   [ResolvedItem] = []
    @Published var allRejected:   [RejectedItem] = []
    @Published var students:      [AppUser]      = []
    @Published var teachers:      [AppUser]      = []
    @Published var committee:     [AppUser]      = []
    @Published var analytics:     Analytics?
    @Published var errorMessage   = ""
    @Published var successMessage = ""
    @Published var isLoading      = false

    func loadUnassigned() async {
        do {
            unassigned = try await APIService.shared.request(
                endpoint: "/admin/unassigned",
                responseType: [Complaint].self
            )
        } catch { errorMessage = error.localizedDescription }
    }

    func loadProgress() async {
        do {
            allProgress = try await APIService.shared.request(
                endpoint: "/progress/all",
                responseType: [ProgressItem].self
            )
        } catch { errorMessage = error.localizedDescription }
    }

    func loadResolved() async {
        do {
            allResolved = try await APIService.shared.request(
                endpoint: "/resolved/all",
                responseType: [ResolvedItem].self
            )
        } catch { errorMessage = error.localizedDescription }
    }

    func loadRejected() async {
        do {
            allRejected = try await APIService.shared.request(
                endpoint: "/rejected/all",
                responseType: [RejectedItem].self
            )
        } catch { errorMessage = error.localizedDescription }
    }

    func loadStudents() async {
        do {
            students = try await APIService.shared.request(
                endpoint: "/users/students",
                responseType: [AppUser].self
            )
        } catch { errorMessage = error.localizedDescription }
    }

    func loadTeachers() async {
        do {
            teachers = try await APIService.shared.request(
                endpoint: "/users/teachers",
                responseType: [AppUser].self
            )
        } catch { errorMessage = error.localizedDescription }
    }

    func loadCommittee() async {
        do {
            committee = try await APIService.shared.request(
                endpoint: "/users/committee",
                responseType: [AppUser].self
            )
        } catch { errorMessage = error.localizedDescription }
    }

    func loadAnalytics() async {
        do {
            analytics = try await APIService.shared.request(
                endpoint: "/admin/analytics",
                responseType: Analytics.self
            )
        } catch { errorMessage = error.localizedDescription }
    }

    func assignComplaint(complaintId: Int, committeeUserId: Int, committeeType: String) async {
        do {
            let body = AssignRequest(
                complaint_id: complaintId,
                committee_user_id: committeeUserId,
                committee_type: committeeType
            )
            _ = try await APIService.shared.request(
                endpoint: "/admin/assign",
                method: "POST",
                body: body,
                responseType: DetailResponse.self
            )
            successMessage = "Complaint assigned successfully"
            await loadUnassigned()
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteStudent(_ userId: Int) async {
        do {
            _ = try await APIService.shared.request(
                endpoint: "/users/students/\(userId)",
                method: "DELETE",
                responseType: DetailResponse.self
            )
            await loadStudents()
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteTeacher(_ userId: Int) async {
        do {
            _ = try await APIService.shared.request(
                endpoint: "/users/teachers/\(userId)",
                method: "DELETE",
                responseType: DetailResponse.self
            )
            await loadTeachers()
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteCommittee(_ userId: Int) async {
        do {
            _ = try await APIService.shared.request(
                endpoint: "/users/committee/\(userId)",
                method: "DELETE",
                responseType: DetailResponse.self
            )
            await loadCommittee()
        } catch { errorMessage = error.localizedDescription }
    }

    func adminConfirmResolved(resolvedId: Int, delete: Bool = false) async {
        do {
            _ = try await APIService.shared.request(
                endpoint: "/resolved/\(resolvedId)/admin-confirm?delete=\(delete)",
                method: "POST",
                responseType: DetailResponse.self
            )
            await loadResolved()
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteRejected(_ rejectedId: Int) async {
        do {
            _ = try await APIService.shared.request(
                endpoint: "/rejected/\(rejectedId)",
                method: "DELETE",
                responseType: DetailResponse.self
            )
            await loadRejected()
        } catch { errorMessage = error.localizedDescription }
    }

    func registerUser(user: UserCreate) async {
        let endpoint: String
        switch user.role {
        case "student":   endpoint = "/users/students"
        case "teacher":   endpoint = "/users/teachers"
        case "committee": endpoint = "/users/committee"
        default: return
        }
        do {
            _ = try await APIService.shared.request(
                endpoint: endpoint,
                method: "POST",
                body: user,
                responseType: AppUser.self
            )
            successMessage = "\(user.role.capitalized) registered successfully"
            switch user.role {
            case "student":   await loadStudents()
            case "teacher":   await loadTeachers()
            case "committee": await loadCommittee()
            default: break
            }
        } catch { errorMessage = error.localizedDescription }
    }
}

// NOTE: CommitteeViewModel has been removed from this file.
// The committee dashboard is now fully handled by CommitteeDashboardViewModel.swift
// which uses the dedicated /api/committee/* endpoints.
