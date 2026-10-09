//
//  UserManager.swift
//  RandumApp
//
//  Created by dannyduy on 8/10/26.
//

import SwiftUI
import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User? = nil
    
    var isLoggedIn: Bool {
        currentUser != nil
    }
    
    init() {
        loadUser()
    }
    
    func loadUser() {
        self.currentUser = UserDefaults.standard.savedUser
    }
    
    func login(user: User) {
        UserDefaults.standard.savedUser = user
        withAnimation {
            self.currentUser = user
        }
    }
    
    func updateUser(_ updatedUser: User) {
        UserDefaults.standard.savedUser = updatedUser
        withAnimation {
            self.currentUser = updatedUser
        }
    }
    
    func logout() {
        UserDefaults.standard.savedUser = nil
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.currentUser)
        withAnimation {
            self.currentUser = nil
        }
    }
}
