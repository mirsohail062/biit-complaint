// Views/Shared/SharedComponents.swift
import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let biitBlue    = Color(red: 0.05, green: 0.32, blue: 0.60)
    static let biitGold    = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let biitBg      = Color(red: 0.96, green: 0.97, blue: 0.99)
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    if let icon { Image(systemName: icon) }
                    Text(title).fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.biitBlue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.biitBlue.opacity(0.1))
            .foregroundColor(Color.biitBlue)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.biitBlue.opacity(0.4)))
        }
    }
}

// MARK: - Custom TextField
struct BIITTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            if let icon { Image(systemName: icon).foregroundColor(.secondary).frame(width: 20) }
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: - Genuineness Score Badge
struct ScoreBadge: View {
    let score: Double

    var color: Color {
        score >= 70 ? .green : score >= 40 ? .orange : .red
    }

    var body: some View {
        Text(String(format: "%.0f%%", score))
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: String

    var color: Color {
        switch status {
        case "resolved":    return .green
        case "rejected":    return .red
        case "in_progress": return .orange
        case "assigned":    return .blue
        default:            return .gray
        }
    }

    var label: String {
        switch status {
        case "in_progress": return "In Progress"
        case "submitted":   return "Submitted"
        default:            return status.capitalized
        }
    }

    var body: some View {
        Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

// MARK: - Section header
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.bold())
            .foregroundColor(Color.biitBlue)
            .padding(.vertical, 4)
    }
}

// MARK: - Empty state
struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Error banner
struct ErrorBanner: View {
    let message: String

    var body: some View {
        if !message.isEmpty {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(message).font(.footnote)
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.red.opacity(0.9))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}
extension Color {
    static let indigoCustom = Color(red: 0.29, green: 0.0, blue: 0.51)
}

// MARK: - BIIT Card (generic content card)
struct BIITCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Complaint Row Card
struct ComplaintRowCard: View {
    let location: String
    let userName: String?
    let date: String
    var score: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(location)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.biitBlue)
                    .lineLimit(1)
                Spacer()
                if let score {
                    ScoreBadge(score: score)
                }
            }
            HStack {
                Label(userName ?? "Unknown", systemImage: "person")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(date.prefix(10).description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Evidence View
struct EvidenceView: View {
    let path: String?
    let type: String?

    var body: some View {
        if let path, !path.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: type == "video" ? "video.fill" : "photo.fill")
                    .foregroundStyle(Color.biitBlue)
                Text("Evidence attached")
                    .font(.caption)
                    .foregroundStyle(Color.biitBlue)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.biitBlue.opacity(0.08))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.biitBlue.opacity(0.2))
            )
        }
    }
}

// MARK: - Involved Students Section
struct InvolvedStudentsSection: View {
    let students: [InvolvedStudentSimple]

    var body: some View {
        if !students.isEmpty {
            BIITCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Involved Students", systemImage: "person.2.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.biitBlue)
                    ForEach(students) { s in
                        HStack {
                            Text(s.full_name).font(.subheadline)
                            Spacer()
                            Text(s.reg_number)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}
