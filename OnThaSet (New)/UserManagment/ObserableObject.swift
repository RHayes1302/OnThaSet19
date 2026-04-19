//
//  ObserableObject.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/11/25.
//

import Foundation

class AuthService: ObservableObject {
    @Published var currentUser: AppUser? = nil

    var isLoggedIn: Bool {
        currentUser != nil
    }

    func loginWithApple(userID: String, email: String) {
        currentUser = AppUser(
            id: userID,
            username: email.components(separatedBy: "@").first ?? "User",
            role: .member
        )
    }

    func logout() {
        currentUser = nil
    }
}
