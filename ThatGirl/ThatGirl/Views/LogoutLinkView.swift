//
//  LogoutLinkView.swift
//  ThatGirl
//
//  Created by Nyaradzo Bere on 1/20/24.
//

import Foundation
import SwiftUI

struct LogoutLink: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        Button(action: {
            sessionStore.signOut()
        }) {
            Text("Logout")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
//                .background(Color.black)
//                .cornerRadius(8)
        }
    }
}


struct LogoutLink_Previews: PreviewProvider {
    static var previews: some View {
        LogoutLink()
    }
}
