//
//  HomeViewModel.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var currentUser: User
    
    init(user: User) {
        self.currentUser = user
    }
}
