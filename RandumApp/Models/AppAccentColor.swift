//
//  AppAccentColor.swift
//  RandumApp
//
//  Created by dannyduy on 22/10/26.
//
import SwiftUI

enum AppAccentColor: String, CaseIterable, Identifiable {
    case indigo = "Indigo"
    case emerald = "Emerald"
    case blue = "Ocean Blue"
    case orange = "Sunset Orange"
    case purple = "Purple"
    case pink = "Rose Pink"
    
    var id: String { rawValue }
    
    var primaryColor: Color {
        switch self {
        case .indigo:  return Color("AccentIndigo", bundle: nil)
        case .emerald: return Color("AccentEmerald", bundle: nil)
        case .blue:    return Color("AccentBlue", bundle: nil)
        case .orange:  return Color("AccentOrange", bundle: nil)
        case .purple:  return Color("AccentPurple", bundle: nil)
        case .pink:    return Color("AccentPink", bundle: nil)
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .indigo:  return Color("BackgroundIndigo", bundle: nil)
        case .emerald: return Color("BackgroundEmerald", bundle: nil)
        case .blue:    return Color("BackgroundBlue", bundle: nil)
        case .orange:  return Color("BackgroundOrange", bundle: nil)
        case .purple:  return Color("BackgroundPurple", bundle: nil)
        case .pink:    return Color("BackgroundPink", bundle: nil)
        }
    }
    
    var inputBackgroundColor: Color {
        switch self {
        case .indigo:  return Color("InputBackgroundIndigo", bundle: nil)
        case .emerald: return Color("InputBackgroundEmerald", bundle: nil)
        case .blue:    return Color("InputBackgroundBlue", bundle: nil)
        case .orange:  return Color("InputBackgroundOrange", bundle: nil)
        case .purple:  return Color("InputBackgroundPurple", bundle: nil)
        case .pink:    return Color("InputBackgroundPink", bundle: nil)
        }
    }
}
