//
//  ToastView.swift
//  BiitComplaintSystem
//
//  Created by Amir's Macbook Pro         on 27/4/2026.
//

import SwiftUI
// MARK: - Toast
struct ToastView: View {
    let message: String
    let color: Color
    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(color.gradient, in: Capsule())
            .padding(.top, 8)
            .shadow(radius: 6)
    }
}
#Preview {
    ToastView(message: "Complaint submitted successfully!", color: .green)
}
