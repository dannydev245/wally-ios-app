//
//  AuthStackScreen.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//

import SwiftUI

struct AuthStackScreens: View {
    @State private var authPath: [AuthRoute] = []
    
    var body: some View {
        NavigationStack(path: $authPath) {
            WelcomeScreen {
                authPath.append(.signIn)
            }
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
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
                    
                default:
                    Text("Screen is being developed!")
                }
            }
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    AuthStackScreens()
}
