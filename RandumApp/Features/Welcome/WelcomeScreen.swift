//
//  WelcomeScreen.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//

import SwiftUI

struct WelcomeScreen: View {
    let onGetStarted: () -> Void
    var body: some View {
        Text("Welcome Screen")
        VStack {
            Button("onGetStarted") {
                onGetStarted()
            }
        }
    }
}

#Preview {
    //    WelcomeScreen()
}
