//
//  SessionStore.swift
//  ThatGirl
//
//  Created by Nyaradzo Bere on 1/20/24.
//

import Foundation
import Firebase
import FirebaseFirestore

class SessionStore: ObservableObject {
    @Published var isUserAuthenticated: AuthState = .undefined
    @Published var hasCompletedProfile = false

    var authRef: Auth!
    private var _authListener: AuthStateDidChangeListenerHandle!

    init(auth: Auth = .auth()) {
        self.authRef = auth
        
        _authListener = self.authRef.addStateDidChangeListener { (auth, user) in
            if let user = user {
                print("User is signed in with uid:", user.uid)
                self.isUserAuthenticated = .signedIn
                self.checkUserProfileCompletion(uid: user.uid)
            } else {
                print("User is not signed in.")
                self.isUserAuthenticated = .signedOut
                self.hasCompletedProfile = false
            }
        }
    }
    
    func signOut() {
        do {
            try authRef.signOut()
//            self.hasCompletedProfile = false
        } catch {
            print("Error signing out")
        }
    }

    private func checkUserProfileCompletion(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.hasCompletedProfile = data?["profileCompleted"] as? Bool ?? false
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "")")
                self.hasCompletedProfile = false
            }
        }
    }
    
    enum AuthState {
        case signedIn
        case signedOut
        case undefined
    }
}
