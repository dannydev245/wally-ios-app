//
//  User.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//
import Foundation

enum Gender: String, CaseIterable, Identifiable, Codable {
    case male = "Male"
    case female = "Female"
    case other = "Others"
    
    var id: String { self.rawValue }
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Others"
        }
    }
}

struct User: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var age: Int
    var gender: Gender
    
    var avatarIconName: String {
        switch gender {
        case .male:
            return "figure.stand"
        case .female:
            return "figure.stand.dress"
        case .other:
            return "person.fill"
        }
    }
}
