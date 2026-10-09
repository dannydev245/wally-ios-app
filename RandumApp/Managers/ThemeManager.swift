//
//  ThemeManager.swift
//  RandumApp
//
//  Created by dannyduy on 7/10/26.
//

import SwiftUI
import Combine

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

enum AppAccentColor: String, CaseIterable, Identifiable {
    case indigo = "Indigo"
    case emerald = "Emerald"
    case blue = "Ocean Blue"
    case orange = "Sunset Orange"
    case purple = "Purple"
    
    var id: String { rawValue }
    
    var primaryColor: Color {
        switch self {
        case .indigo:  return Color("AccentIndigo", bundle: nil)
        case .emerald: return Color("AccentEmerald", bundle: nil)
        case .blue:    return Color("AccentBlue", bundle: nil)
        case .orange:  return Color("AccentOrange", bundle: nil)
        case .purple:  return Color("AccentPurple", bundle: nil)
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .indigo:  return Color("BackgroundIndigo", bundle: nil)
        case .emerald: return Color("BackgroundEmerald", bundle: nil)
        case .blue:    return Color("BackgroundBlue", bundle: nil)
        case .orange:  return Color("BackgroundOrange", bundle: nil)
        case .purple:  return Color("BackgroundPurple", bundle: nil)
        }
    }
    
    var inputBackgroundColor: Color {
        switch self {
        case .indigo:  return Color("InputBackgroundIndigo", bundle: nil)
        case .emerald: return Color("InputBackgroundEmerald", bundle: nil)
        case .blue:    return Color("InputBackgroundBlue", bundle: nil)
        case .orange:  return Color("InputBackgroundOrange", bundle: nil)
        case .purple:  return Color("InputBackgroundPurple", bundle: nil)
        }
    }
}

enum CurrencyType: String, CaseIterable, Identifiable {
    case vnd = "VND (₫)"
    case usd = "USD ($)"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .vnd: return "₫"
        case .usd: return "$"
        }
    }
    
    func format(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        
        switch self {
        case .vnd:
            formatter.maximumFractionDigits = 0
            let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
            return "\(formattedNumber) ₫"
            
        case .usd:
            formatter.maximumFractionDigits = 0
            let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
            return "$\(formattedNumber)"
        }
    }
    
    func formatCompact(amount: Double) -> String {
        let absAmount = abs(amount)
        let sign = amount < 0 ? "-" : ""
        
        switch self {
        case .vnd:
            if absAmount >= 1_000_000_000 {
                return "\(sign)\(String(format: "%.1f", absAmount / 1_000_000_000))B ₫"
            } else if absAmount >= 1_000_000 {
                return "\(sign)\(String(format: "%.1f", absAmount / 1_000_000))M ₫"
            } else if absAmount >= 1_000 {
                return "\(sign)\(String(format: "%.0f", absAmount / 1_000))k ₫"
            } else {
                return "\(sign)\(Int(absAmount)) ₫"
            }
            
        case .usd:
            if absAmount >= 1_000_000_000 {
                return "\(sign)$\(String(format: "%.1f", absAmount / 1_000_000_000))B"
            } else if absAmount >= 1_000_000 {
                return "\(sign)$\(String(format: "%.1f", absAmount / 1_000_000))M"
            } else if absAmount >= 1_000 {
                return "\(sign)$\(String(format: "%.0f", absAmount / 1_000))k"
            } else {
                return "\(sign)$\(String(format: "%.0f", absAmount))"
            }
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage(AppStorageKeys.appAccentColor) var selectedAccentRaw: String = AppAccentColor.indigo.rawValue
    @AppStorage(AppStorageKeys.appTheme) var selectedThemeRaw: String = AppThemeMode.system.rawValue
    @AppStorage(AppStorageKeys.appCurrency) var selectedCurrencyRaw: String = CurrencyType.vnd.rawValue
    
    var currentAccent: AppAccentColor {
        get { AppAccentColor(rawValue: selectedAccentRaw) ?? .indigo }
        set {
            selectedAccentRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    var currentTheme: AppThemeMode {
        get { AppThemeMode(rawValue: selectedThemeRaw) ?? .system }
        set {
            selectedThemeRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    var currentCurrency: CurrencyType {
        get { CurrencyType(rawValue: selectedCurrencyRaw) ?? .vnd }
        set {
            selectedCurrencyRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
}


