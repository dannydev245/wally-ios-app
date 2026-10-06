//
//  UIHelpers.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import SwiftUI

// MARK: - Custom Shapes
struct TopRoundedCorner: Shape {
    var radius: CGFloat = 36
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Extension giúp gọi bo góc trên nhanh và ngắn gọn hơn
extension View {
    func cornerRadiusTop(_ radius: CGFloat = 36) -> some View {
        self.clipShape(TopRoundedCorner(radius: radius))
    }
}

// MARK: - Button Styles
struct AppPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - formatVND
func formatVND(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "vi_VN")
    return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount)) ₫"
}

// MARK: - formatCompactNumber
func formatCompactNumber(_ number: Double) -> String {
    if number >= 1_000_000_000 {
        return String(format: "%.1fB", number / 1_000_000_000)
    } else if number >= 1_000_000 {
        return String(format: "%.1fM", number / 1_000_000)
    } else if number >= 1_000 {
        return String(format: "%.0fK", number / 1_000)
    }
    return "\(Int(number))"
}
