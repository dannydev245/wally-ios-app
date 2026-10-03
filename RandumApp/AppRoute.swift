//
//  AppRoute.swift
//  RandumApp
//
//  Created by dannyduy on 1/10/26.
//

import Foundation

enum AuthRoute: Hashable {
    case welcome
    case getUserInfo
//    case signIn
//    case signUp
//    case forgotPassword
}

enum MainRoute: Hashable {
    case home
    case transaction
    case analyze
    case profile
}

enum AppRoute: Hashable {
    case auth(AuthRoute)
    case main(MainRoute)
}
