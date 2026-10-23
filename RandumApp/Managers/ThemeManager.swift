//
//  ThemeManager.swift
//  RandumApp
//
//  Created by dannyduy on 7/10/26.
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage(AppStorageKeys.appAccentColor) var selectedAccentRaw: String = AppAccentColor.indigo.rawValue
    @AppStorage(AppStorageKeys.appTheme) var selectedThemeRaw: String = AppThemeMode.system.rawValue
    @AppStorage(AppStorageKeys.appCurrency) var selectedCurrencyRaw: String = CurrencyType.vnd.rawValue
    @AppStorage(AppStorageKeys.appLanguage) var selectedLanguageRaw: String = AppLanguage.system.rawValue {
        didSet { objectWillChange.send() }
    }
    
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
    
    var currentLanguage: AppLanguage {
        AppLanguage(rawValue: selectedLanguageRaw) ?? .system
    }
}


