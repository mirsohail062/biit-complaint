// Notification components.swift - Updated version

//
//  NotificationsTabView.swift
//  BiitComplaintSystem
//

import SwiftUI

// MARK: - Date Extension for shortDate
extension String {
    var shortDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: self) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            return displayFormatter.string(from: date)
        }
        return self.prefix(10).description
    }
}

// MARK: - Notifications Tab
struct NotificationsTabView: View {
    @ObservedObject var vm: CommitteeDashboardViewModel

    var body: some View {
        NavigationStack {
            Group {
                if vm.notifications.isEmpty {
                    EmptyStateView(icon: "bell.slash", message: "No messages yet")
                } else {
                    List(vm.notifications) { notif in
                        NavigationLink {
                            NotificationDetailView(notif: notif, vm: vm)
                        } label: {
                            NotificationRowView(notif: notif)
                        }
                        .listRowBackground(notif.is_read ? Color(.systemBackground) : Color(red: 0.29, green: 0.0, blue: 0.51).opacity(0.05))
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if vm.unreadCount > 0 {
                        Text("\(vm.unreadCount) unread")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(red: 0.29, green: 0.0, blue: 0.51))
                    }
                }
            }
            .refreshable { await vm.loadAll() }
        }
    }
}

struct NotificationRowView: View {
    let notif: CommitteeNotification
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(notif.is_read ? Color(.systemGray5) : Color(red: 0.29, green: 0.0, blue: 0.51).opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: notif.is_read ? "bell" : "bell.badge.fill")
                    .foregroundStyle(notif.is_read ? .secondary : Color(red: 0.29, green: 0.0, blue: 0.51))
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notif.sender_name ?? "System")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(notif.sent_at.shortDate)
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Text(notif.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if notif.reply != nil {
                    Label("Replied", systemImage: "arrowshape.turn.up.left.fill")
                        .font(.caption2).foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Notification Detail
struct NotificationDetailView: View {
    let notif: CommitteeNotification
    @ObservedObject var vm: CommitteeDashboardViewModel
    @State private var showReplySheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Message bubble
                InfoCard(title: "Message from \(notif.sender_name ?? "Admin")",
                         icon: "person.crop.circle", color: Color(red: 0.29, green: 0.0, blue: 0.51)) {
                    Text(notif.message).font(.body)
                }

                // Reply (if exists)
                if let reply = notif.reply {
                    InfoCard(title: "Your Reply", icon: "arrowshape.turn.up.left", color: .green) {
                        Text(reply).font(.body)
                    }
                }

                // Complaint reference
                if let cid = notif.complaint_id {
                    HStack {
                        Label("Related to Complaint #\(cid)", systemImage: "link")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                if notif.reply == nil {
                    Button {
                        vm.replyText = ""
                        showReplySheet = true
                    } label: {
                        Label("Write Reply", systemImage: "arrowshape.turn.up.left.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.29, green: 0.0, blue: 0.51), in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Message")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.markRead(notification: notif)
        }
        .sheet(isPresented: $showReplySheet) {
            NavigationStack {
                Form {
                    Section("Your Reply") {
                        TextEditor(text: $vm.replyText)
                            .frame(minHeight: 120)
                    }
                }
                .navigationTitle("Reply")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showReplySheet = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Send") {
                            showReplySheet = false
                            Task { await vm.reply(notification: notif) }
                        }
                        .disabled(vm.replyText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
