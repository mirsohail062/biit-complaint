
import Foundation
import Combine

@MainActor
final class CommitteeDashboardViewModel: ObservableObject {

    // MARK: - Published State
    @Published var dashboard: CommitteeDashboard?
    @Published var assigned: [AssignedComplaintItem] = []
    @Published var inProgress: [InProgressItem] = []
    @Published var resolved: [CommitteeResolvedItem] = []
    @Published var rejected: [CommitteeRejectedItem] = []
    @Published var notifications: [CommitteeNotification] = []

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Action sheet state
    @Published var resolveNote = ""
    @Published var rejectReason = ""
    @Published var replyText = ""

    private let service = CommitteeService.shared

    // MARK: - Load All Data
    func loadAll() async {
        isLoading = true
        errorMessage = nil
        async let dash  = service.fetchDashboard()
        async let asgn  = service.fetchAssigned()
        async let prog  = service.fetchInProgress()
        async let res   = service.fetchResolved()
        async let rej   = service.fetchRejected()
        async let notif = service.fetchNotifications()
        do {
            (dashboard, assigned, inProgress, resolved, rejected, notifications) =
                try await (dash, asgn, prog, res, rej, notif)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Accept Assigned Complaint
    func accept(item: AssignedComplaintItem) async {
        do {
            _ = try await service.acceptComplaint(assignedId: item.assigned_id)
            successMessage = "Complaint accepted and moved to In Progress."
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Resolve In-Progress Complaint
    func resolve(item: InProgressItem) async {
        let note = resolveNote.trimmingCharacters(in: .whitespaces)
        guard !note.isEmpty else { errorMessage = "Resolution note cannot be empty."; return }
        do {
            _ = try await service.resolveComplaint(
                progressId: item.progress_id,
                complaintId: item.complaint.complaint_id,
                note: note
            )
            resolveNote = ""
            successMessage = "Complaint resolved successfully."
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reject In-Progress Complaint
    func reject(item: InProgressItem) async {
        let reason = rejectReason.trimmingCharacters(in: .whitespaces)
        guard !reason.isEmpty else { errorMessage = "Rejection reason cannot be empty."; return }
        do {
            _ = try await service.rejectComplaint(
                progressId: item.progress_id,
                complaintId: item.complaint.complaint_id,
                reason: reason
            )
            rejectReason = ""
            successMessage = "Complaint rejected."
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reply Notification
    func reply(notification: CommitteeNotification) async {
        let text = replyText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { errorMessage = "Reply cannot be empty."; return }
        do {
            _ = try await service.replyToNotification(id: notification.notification_id, reply: text)
            replyText = ""
            successMessage = "Reply sent."
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Mark Read
    func markRead(notification: CommitteeNotification) async {
        guard !notification.is_read else { return }
        do {
            _ = try await service.markNotificationRead(id: notification.notification_id)
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var unreadCount: Int {
        notifications.filter { !$0.is_read }.count
    }
}
