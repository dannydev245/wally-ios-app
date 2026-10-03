//
//  AuthStackScreen.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//

import SwiftUI

struct AuthStackScreens: View {
    @State private var authPath: [AuthRoute] = []
    var onUserAuthenticated: (User) -> Void
    
    var body: some View {
        NavigationStack(path: $authPath) {
            WelcomeScreen {
                authPath.append(.getUserInfo)
            }
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .getUserInfo:
                    GetUserInfoScreen{ user in
                        onUserAuthenticated(user)
                    }
                    /**
                     case .signIn:
                     SignInScreen (
                     onNavigate: { nextRoute in
                     authPath.append(nextRoute)
                     }
                     )
                     .navigationBarBackButtonHidden(true)
                     
                     case .signUp:
                     SignUpScreen(
                     onGoToSignIn: {
                     authPath.append(.signIn)
                     }
                     )
                     
                     case .forgotPassword:
                     ForgotPasswordScreen(
                     onGoToSignIn: {
                     authPath.append(.signIn)
                     }
                     )
                     */
                default:
                    Text("Screen is being developed!")
                }
            }
        }
        .tint(AppColors.primary)
    }
}
