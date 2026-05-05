// Views/Complaints/AddComplaintView.swift
import SwiftUI
import PhotosUI

struct AddComplaintView: View {
    @StateObject private var vm = ComplaintViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.biitBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // ── Category ──────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Complaint Category", systemImage: "list.bullet")
                                .font(.subheadline.bold())
                            Picker("Category", selection: $vm.selectedCategory) {
                                Text("Select Category").tag(Optional<Category>(nil))
                                ForEach(vm.categories) { cat in
                                    Text(cat.name).tag(Optional(cat))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.05), radius: 3)
                            .onChange(of: vm.selectedCategory) { _, _ in
                                vm.selectedSubcategory = nil
                            }
                        }

                        // ── Subcategory ───────────────────────────────
                        if let cat = vm.selectedCategory, !cat.subcategories.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Subcategory", systemImage: "tag")
                                    .font(.subheadline.bold())
                                Picker("Subcategory", selection: $vm.selectedSubcategory) {
                                    Text("Select Subcategory").tag(Optional<Subcategory>(nil))
                                    ForEach(cat.subcategories) { sub in
                                        Text(sub.name).tag(Optional(sub))
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.05), radius: 3)
                            }
                        }

                        // ── Date & Time ───────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Date & Time of Incident", systemImage: "calendar.clock")
                                .font(.subheadline.bold())
                            DatePicker("", selection: $vm.form.incidentDate, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                        }

                        // ── Location ──────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Location", systemImage: "mappin.and.ellipse")
                                .font(.subheadline.bold())
                            BIITTextField(placeholder: "Describe where the issue occurred", text: $vm.form.location)
                        }

                        // ── Description ───────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Description", systemImage: "text.alignleft")
                                    .font(.subheadline.bold())
                                Spacer()
                                Text("\(vm.form.description.count)/500")
                                    .font(.caption)
                                    .foregroundColor(vm.form.description.count > 490 ? .red : .secondary)
                            }
                            TextEditor(text: $vm.form.description)
                                .frame(height: 120)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.05), radius: 3)
                                .onChange(of: vm.form.description) { _, newValue in
                                    if newValue.count > 500 {
                                        vm.form.description = String(newValue.prefix(500))
                                    }
                                }
                        }

                        // ── Involved Students ─────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Involved Students (Optional)", systemImage: "person.badge.plus")
                                .font(.subheadline.bold())

                            HStack(spacing: 10) {
                                BIITTextField(placeholder: "Full Name", text: $vm.involvedName)
                                BIITTextField(placeholder: "Reg. No.", text: $vm.involvedReg)
                                Button {
                                    vm.addInvolvedStudent()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.biitBlue)
                                }
                            }

                            ForEach(Array(zip(vm.form.involvedNames, vm.form.involvedRegs).enumerated()), id: \.offset) { idx, pair in
                                HStack {
                                    Image(systemName: "person.fill").foregroundColor(.biitBlue)
                                    Text("\(pair.0) – \(pair.1)").font(.footnote)
                                    Spacer()
                                    Button {
                                        vm.form.involvedNames.remove(at: idx)
                                        vm.form.involvedRegs.remove(at: idx)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                    }
                                }
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(8)
                            }
                        }

                        // ── Evidence ──────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Evidence (Image/Video)", systemImage: "paperclip")
                                .font(.subheadline.bold())

                            PhotosPicker(selection: $vm.evidenceItem, matching: .any(of: [.images, .videos])) {
                                HStack {
                                    Image(systemName: vm.evidenceData == nil ? "icloud.and.arrow.up" : "checkmark.circle.fill")
                                    Text(vm.evidenceData == nil ? "Attach File" : "File Selected")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.biitBlue.opacity(0.08))
                                .foregroundColor(Color.biitBlue)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.biitBlue.opacity(0.3), style: StrokeStyle(dash: [5])))
                            }
                            .onChange(of: vm.evidenceItem) { _, _ in
                                Task {
                                    await vm.loadEvidenceData()
                                }
                            }
                        }

                        ErrorBanner(message: vm.errorMessage)

                        // ── Submit ────────────────────────────────────
                        PrimaryButton(title: "Submit Complaint", icon: "paperplane.fill", isLoading: vm.isLoading) {
                            Task {
                                await vm.submitComplaint()
                                if vm.successMessage != "" { showSuccess = true }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Complaint")
            .navigationBarTitleDisplayMode(.inline)
            .task { await vm.loadCategories() }
            .alert("Submitted!", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your complaint has been submitted successfully.")
            }
        }
    }
}
#Preview {
    AddComplaintView()
}
