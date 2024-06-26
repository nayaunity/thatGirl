//
//  ThatGirlApp.swift
//  ThatGirl
//
//  Created by Nyaradzo Bere on 1/20/24.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct ThatGirlApp: App {
    @StateObject private var sessionStore = SessionStore()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            if sessionStore.isUserAuthenticated == .signedIn {
                if sessionStore.hasCompletedProfile {
                    ContentView()
                        .environmentObject(sessionStore)
                } else {
                    CreateProfileView()
                        .environmentObject(sessionStore)
                }
            } else {
                LoginSignupView()
                    .environmentObject(sessionStore)
            }
        }
    }
}
