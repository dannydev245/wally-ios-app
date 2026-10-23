//
//  AppLanguage.swift
//  RandumApp
//
//  Created by dannyduy on 22/10/26.
//
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "System"
    case en = "English"
    case vi = "Vietnamese"
    
    var id: String { rawValue }
    
    var title: LocalizedStringResource {
        switch self {
        case .system:
            return "System"
        case .en:
            return "English"
        case .vi:
            return "Vietnamese"
        }
    }
    
    var code: String {
        switch self {
        case .system:
            let systemCode = Locale.current.language.languageCode?.identifier ?? "en"
            return systemCode.hasPrefix("vi") ? "vi" : "en"
        case .en:
            return "en"
        case .vi:
            return "vi"
        }
    }
    
    var locale: Locale {
        Locale(identifier: code)
    }
}
