//
//  ObserableObject.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/11/25.
//

import Foundation

class AuthService: ObservableObject {
    @Published var currentUser: AppUser? = nil
    
    // Check if someone is logged in
    var isLoggedIn: Bool {
        currentUser != nil
    }
    
    // Password-based login (old method)
    func login(password: String) -> Bool {
        if password == "SetMember77" {
            currentUser = AppUser(id: UUID().uuidString, username: "Member", role: UserRole.member)
            return true
        } else if password == "AdminOnTheSet2025" {
            currentUser = AppUser(id: "admin_1", username: "Admin", role: UserRole.admin)
            return true
        }
        return false
    }
    
    // Apple Sign In login (no password needed)
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
