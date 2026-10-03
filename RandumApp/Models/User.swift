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
    
    var displayName: String {
        return self.rawValue
    }
}

struct User: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var age: Int
    var gender: Gender
}
