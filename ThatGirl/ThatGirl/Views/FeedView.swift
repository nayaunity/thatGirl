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
}

struct FeedView: View {
    @State private var statusText: String = ""
    @State private var userGroupIds: [String] = []
    @State private var groupStatuses: [Status] = []
    @State private var isLoading: Bool = false
    let currentUserId = Auth.auth().currentUser?.uid

    var body: some View {
        VStack {
            // Status Input Area
            VStack(alignment: .leading, spacing: 8) {
                Text("Share your status:")
                    .font(.headline)

                TextField("What's on your mind?", text: $statusText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Post", action: postStatus)
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)

            if isLoading {
                ProgressView()
            } else {
                List(groupStatuses) { status in
                    VStack(alignment: .leading) {
                        Text(status.text)
                        Text("Posted by \(status.userId)")
                            .font(.caption)
                        Text("On \(status.timestamp, formatter: dateFormatter)")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .onAppear(perform: fetchUserGroupIds)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    private func fetchUserGroupIds() {
        isLoading = true
        let db = Firestore.firestore()
        // Assuming you have the user's ID stored in UserDefaults or passed down
        guard let userId = currentUserId else {
            print("User ID not found")
            return
        }
        
        db.collection("groups")
          .whereField("members", arrayContains: userId)
          .getDocuments { (querySnapshot, error) in
              if let error = error {
                  print("Error getting groups: \(error)")
                  isLoading = false
              } else {
                  userGroupIds = querySnapshot?.documents.map { $0.documentID } ?? []
                  fetchGroupStatuses()
              }
          }
    }

    private func postStatus() {
        guard let groupId = userGroupIds.first else {
            print("No group ID available")
            return
        }

        let db = Firestore.firestore()
        let statusData: [String: Any] = [
            "userId": currentUserId,
            "text": statusText,
            "timestamp": Timestamp(date: Date()),
            "groupId": groupId
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

    private func fetchGroupStatuses() {
        guard let groupId = userGroupIds.first else {
            isLoading = false
            return
        }

        let db = Firestore.firestore()
        db.collection("statuses")
          .whereField("groupId", isEqualTo: groupId)
          .order(by: "timestamp", descending: true)
          .getDocuments { (querySnapshot, err) in
              if let err = err {
                  print("Error getting statuses: \(err)")
                  isLoading = false
              } else {
                  groupStatuses = querySnapshot?.documents.compactMap { document -> Status? in
                      try? document.data(as: Status.self)
                  } ?? []
                  isLoading = false
              }
          }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
