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

    var authRef: Auth!
    private var _authListener: AuthStateDidChangeListenerHandle!

    init(auth: Auth = .auth()) {
        self.authRef = auth
        
        _authListener = self.authRef.addStateDidChangeListener { (auth, user) in
            if let user = user {
                print("User is signed in with uid:", user.uid)
                self.isUserAuthenticated = .signedIn
            } else {
                print("User is not signed in.")
                self.isUserAuthenticated = .signedOut
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
