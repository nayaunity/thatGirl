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
    @State private var statusText: String = ""
    @State private var groupStatuses: [Status] = []
    @State private var isLoading: Bool = false
    private let currentGroupId: String = "your_current_group_id" // Replace with actual group ID

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
            } else {
                List(groupStatuses) { status in
                    HStack {
                        if let imageUrl = status.userProfileImageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                            } placeholder: {
                                Circle().fill(Color.gray)
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        }

                        VStack(alignment: .leading) {
                            Text(status.text)
                            Text(timeElapsedSince(date: status.timestamp))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear(perform: fetchGroupStatuses)
    }

    private func postStatus() {
        let db = Firestore.firestore()
        let statusData: [String: Any] = [
            "userId": Auth.auth().currentUser?.uid ?? "Unknown",
            "text": statusText,
            "timestamp": Timestamp(date: Date()),
            "groupId": currentGroupId
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
        isLoading = true
        let db = Firestore.firestore()
        db.collection("statuses")
          .whereField("groupId", isEqualTo: currentGroupId)
          .order(by: "timestamp", descending: true)
          .getDocuments { (querySnapshot, error) in
              if let error = error {
                  print("Error getting statuses: \(error)")
                  self.isLoading = false
              } else {
                  guard let documents = querySnapshot?.documents else {
                      self.isLoading = false
                      return
                  }
                  self.groupStatuses = documents.compactMap { doc -> Status? in
                      var status = try? doc.data(as: Status.self)
                      fetchUserProfileImage(userId: status?.userId ?? "", completion: { url in
                          status?.userProfileImageUrl = url
                          self.groupStatuses = self.groupStatuses.map { $0.id == status?.id ? status! : $0 }
                      })
                      return status
                  }
                  self.isLoading = false
              }
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
