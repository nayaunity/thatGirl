//
//  FeedView.swift
//  ThatGirl
//
//  Created by Nyaradzo Bere on 1/20/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore

// Status model
struct Status: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let text: String
    let timestamp: Date
    let groupId: String
    var userProfileImageUrl: String?
}

// View
struct FeedView: View {
    @EnvironmentObject var sessionStore: SessionStore // Assuming this has the current user's ID
    @State private var statusText: String = ""
    @State private var groupStatuses: [Status] = []
    @State private var isLoading: Bool = false
    @State private var userGroupIds: [String] = []

    var body: some View {
        VStack {
            Text("Share your status:")
                .font(.headline)
            
            HStack {
                TextField("What's on your mind?", text: $statusText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Post", action: postStatus)
                    .padding()
                    .background(HexColor.fromHex("A888FF"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            if isLoading {
                Spacer()
                ProgressView()
            } else if userGroupIds.isEmpty {
                Text("You are not in any group.")
                Spacer()
            } else {
                List(groupStatuses) { status in
                    // Status view code
                }
            }
        }
        .padding()
        .onAppear(perform: fetchUserGroups)
    }

    private func postStatus() {
        guard let firstGroupId = userGroupIds.first else {
            print("User is not part of any group.")
            return
        }

        let db = Firestore.firestore()
        let statusData: [String: Any] = [
            "userId": Auth.auth().currentUser?.uid ?? "Unknown",
            "text": statusText,
            "timestamp": Timestamp(date: Date()),
            "groupId": firstGroupId  // Use the first group ID
        ]

        db.collection("statuses").addDocument(data: statusData) { error in
            if let error = error {
                print("Error posting status: \(error)")
            } else {
                statusText = ""
                fetchGroupStatuses()
            }
        }
    }

    private func fetchUserGroups() {
        isLoading = true
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }

        let db = Firestore.firestore()
        db.collection("groups")
          .whereField("members", arrayContains: userId)
          .getDocuments { (querySnapshot, error) in
              if let error = error {
                  print("Error getting groups: \(error)")
                  self.isLoading = false
              } else {
                  self.userGroupIds = querySnapshot?.documents.map { $0.documentID } ?? []
                  self.fetchGroupStatuses()
              }
          }
    }

    private func fetchGroupStatuses() {
        guard !userGroupIds.isEmpty else {
            isLoading = false
            return
        }

        let db = Firestore.firestore()
        db.collection("statuses")
          .whereField("groupId", in: userGroupIds)
          .order(by: "timestamp", descending: true)
          .getDocuments { (querySnapshot, error) in
              // Status fetching and processing code
          }
    }

    
    private func fetchUserProfileImage(userId: String, completion: @escaping (String) -> Void) {
            let db = Firestore.firestore()
            db.collection("users").document(userId).getDocument { (document, error) in
                if let document = document, document.exists {
                    let data = document.data()
                    let imageUrl = data?["profilePictureUrl"] as? String ?? ""
                    completion(imageUrl)
                } else {
                    print("Document does not exist")
                    completion("")
                }
            }
        }

        func timeElapsedSince(date: Date) -> String {
            let timeInterval = Date().timeIntervalSince(date)
            let minute = 60.0
            let hour = 60.0 * minute
            let day = 24.0 * hour

            if timeInterval < hour {
                return "\(Int(timeInterval / minute)) minutes ago"
            } else if timeInterval < day {
                return "\(Int(timeInterval / hour)) hours ago"
            } else {
                return "\(Int(timeInterval / day)) days ago"
            }
        }
}

// Preview
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
