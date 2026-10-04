//
//  HomeScreen.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import SwiftUI

struct HomeScreen: View {
    @StateObject private var viewModel: HomeViewModel
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(user: user))
    }
    
    var body: some View {
        VStack{
            Text("eyo wassup ku")
            Text("Xin chào, \(viewModel.currentUser.name)!")
        }
    }
}

#Preview {
    HomeScreen(user: User(id: UUID(), name: "Duy Hoang Thanh", age: 22, gender: .male))
}
