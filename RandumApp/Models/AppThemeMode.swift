//
//  AppThemeMode.swift
//  RandumApp
//
//  Created by dannyduy on 22/10/26.
//
import SwiftUI

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
