//
//  ForgotPasswordScreen.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//

import SwiftUI

struct ForgotPasswordScreen: View {
    let onGoToSignIn: () -> Void
    var body: some View {
        Text("ForgotPasswordScreen")
        Button("onGoToSignIn") {
            onGoToSignIn()
        }
    }
}

#Preview {
//    ForgotPasswordScreen()
}
