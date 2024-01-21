//
//  SessionStore.swift
//  ThatGirl
//
//  Created by Nyaradzo Bere on 1/20/24.
//

import Foundation
import Firebase

class SessionStore: ObservableObject {
    @Published var isUserAuthenticated: AuthState = .undefined
//    @Published var hasCompletedProfile = false  // New property to track profile completion

    var authRef: Auth!
    private var _authListener: AuthStateDidChangeListenerHandle!

    init(auth: Auth = .auth()) {
        self.authRef = auth
        
        _authListener = self.authRef.addStateDidChangeListener { (auth, user) in
            if let user = user {
                print("User is signed in with uid:", user.uid)
                // Update the authentication state but don't change the profile completion state here.
                self.isUserAuthenticated = .signedIn
            } else {
                print("User is not signed in.")
                self.isUserAuthenticated = .signedOut
                // Reset profile completion state when signed out
//                self.hasCompletedProfile = false
            }
        }
    }
    
    func signOut() {
        do {
            try authRef.signOut()
        } catch {
            print("Error signing out")
        }
    }
    
    enum AuthState {
        case signedIn
        case signedOut
        case undefined
    }
}
