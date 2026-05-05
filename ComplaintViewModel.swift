// ViewModels/ComplaintViewModel.swift
import Foundation
import Combine
import SwiftUI

import PhotosUI

@MainActor
final class ComplaintViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var myComplaints: [Complaint] = []
    @Published var myProgress: [ProgressItem] = []
    @Published var myResolved: [ResolvedItem] = []
    @Published var myRejected: [RejectedItem] = []

    @Published var form = ComplaintForm()
    @Published var selectedCategory: Category?
    @Published var selectedSubcategory: Subcategory?
    @Published var evidenceItem: PhotosPickerItem?
    @Published var evidenceData: Data?
    @Published var evidenceMime: String = "image/jpeg"

    @Published var isLoading = false
    @Published var successMessage = ""
    @Published var errorMessage = ""

    // Involved students form helpers
    @Published var involvedName = ""
    @Published var involvedReg  = ""

    func loadCategories() async {
        do {
            categories = try await APIService.shared.request(
                endpoint: "/categories/",
                responseType: [Category].self
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMyComplaints() async {
        do {
            myComplaints = try await APIService.shared.request(
                endpoint: "/complaints/mine",
                responseType: [Complaint].self
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMyProgress() async {
        do {
            myProgress = try await APIService.shared.request(
                endpoint: "/progress/mine",
                responseType: [ProgressItem].self
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMyResolved() async {
        do {
            myResolved = try await APIService.shared.request(
                endpoint: "/resolved/mine",
                responseType: [ResolvedItem].self
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMyRejected() async {
        do {
            myRejected = try await APIService.shared.request(
                endpoint: "/rejected/mine",
                responseType: [RejectedItem].self
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addInvolvedStudent() {
        guard !involvedName.isEmpty, !involvedReg.isEmpty else { return }
        form.involvedNames.append(involvedName)
        form.involvedRegs.append(involvedReg)
        involvedName = ""
        involvedReg  = ""
    }

    func removeInvolved(at offsets: IndexSet) {
        form.involvedNames.remove(atOffsets: offsets)
        form.involvedRegs.remove(atOffsets: offsets)
    }

    func loadEvidenceData() async {
        guard let item = evidenceItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            evidenceData = data
            evidenceMime = "image/jpeg"
        }
    }

    func submitComplaint() async {
        guard let cat = selectedCategory, let sub = selectedSubcategory else {
            errorMessage = "Please select category and subcategory"
            return
        }
        guard !form.location.isEmpty, !form.description.isEmpty else {
            errorMessage = "Location and description are required"
            return
        }
        if form.description.count > 500 {
            errorMessage = "Description must be 500 characters or less"
            return
        }

        form.categoryId    = cat.category_id
        form.subcategoryId = sub.subcategory_id

        isLoading = true
        errorMessage = ""
        do {
            let msg = try await APIService.shared.submitComplaint(
                form: form,
                evidenceData: evidenceData,
                evidenceMime: evidenceData != nil ? evidenceMime : nil
            )
            successMessage = msg
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func submitFeedback(resolvedId: Int, feedback: String) async {
        struct FeedbackBody: Encodable { let feedback: String }
        do {
            _ = try await APIService.shared.request(
                endpoint: "/resolved/\(resolvedId)/feedback",
                method: "POST",
                body: FeedbackBody(feedback: feedback),
                responseType: DetailResponse.self
            )
            await loadMyResolved()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resetForm() {
        form          = ComplaintForm()
        selectedCategory    = nil
        selectedSubcategory = nil
        evidenceItem  = nil
        evidenceData  = nil
        involvedName  = ""
        involvedReg   = ""
    }
}
