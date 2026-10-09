//
//  AppColors.swift
//  RandumApp
//
//  Created by dannyduy on 1/10/26.
//

import SwiftUI

enum AppColors {
    static var primary: Color {
        ThemeManager.shared.currentAccent.primaryColor
    }
    static var background: Color {
        ThemeManager.shared.currentAccent.backgroundColor
    }
    static var inputBackground: Color {
        ThemeManager.shared.currentAccent.inputBackgroundColor
    }
    static let textPrimary = Color("TextPrimary", bundle: nil)
    static let textSecondary = Color("TextSecondary", bundle: nil)
    static let greenEmerald = Color("GreenEmerald", bundle: nil)
    static let redBright = Color("RedBright", bundle: nil)
}
