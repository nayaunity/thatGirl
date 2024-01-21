//
//  ContentView.swift
//  ThatGirl
//
//  Created by Nyaradzo Bere on 1/20/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        NavigationView {
            TabView {
                DailyChecklistView()
                    .tabItem {
                        Label("Checklist", systemImage: "checkmark.circle")
                    }
                FeedView()
                    .tabItem {
                        Label("Feed", systemImage: "newspaper")
                    }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    sessionStore.signOut()
                }) {
                    Text("Logout")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
