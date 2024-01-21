//
//  LoginSignupView.swift
//  ThatGirl
//
//  Created by Nyaradzo Bere on 1/20/24.
//

import SwiftUI
import Firebase

struct LoginSignupView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var navigateToProfileCreation = false
    @State private var navigateToFeedView = false
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                    
                    Button("Sign Up") {
                        signUp()
                    }
                    .padding()
                    
                    Button("Login") {
                        login()
                    }
                    .padding()
                    
                    // Navigation Link to Profile Creation View
                    NavigationLink(destination: CreateProfileView(), isActive: $navigateToProfileCreation) {
                        EmptyView()
                    }
                    NavigationLink(destination: FeedView(), isActive: $navigateToFeedView) {
                        EmptyView()
                    }
                }
                .padding()
            }
        }
    }

    func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                print("SignUp Error: \(error.localizedDescription)")
            } else {
                self.navigateToProfileCreation = true
            }
        }
    }

    func login() {
        // Handle login logic
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Login Error: \(error.localizedDescription)")
            } else {
                self.navigateToFeedView = true
            }
        }
    }
}

struct LoginSignupView_Previews: PreviewProvider {
    static var previews: some View {
        LoginSignupView()
    }
}
