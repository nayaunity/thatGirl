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
import FirebaseStorage

// Status model
struct Status: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let text: String
    let timestamp: Date
    let groupId: String
    var userProfileImageUrl: String?
    var imageUrl: String?
}

// CustomListItem struct
struct CustomListItem: View {
    let status: Status

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            userProfileImage
            VStack(alignment: .leading, spacing: 5) {
                Text(status.text)
                    .font(.body)
                    .foregroundColor(.primary)
                if let imageUrl = status.imageUrl, let url = URL(string: imageUrl) {
                    statusImage(url: url)
                }
                Text(timeElapsedSince(date: status.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }

    private var userProfileImage: some View {
        // Define the user profile image view
        Group {
            if let imageUrl = status.userProfileImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(Color.gray)
                }
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle().fill(Color.gray)
                    .frame(width: 40, height: 40)
            }
        }
    }

    private func statusImage(url: URL) -> some View {
        // Define the status image view
        AsyncImage(url: url) { image in
            image.resizable()
        } placeholder: {
            ProgressView()
        }
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: .infinity)
        .cornerRadius(10)
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

// FeedView struct
struct FeedView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var statusText: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var groupStatuses: [Status] = []
    @State private var isLoading: Bool = false
    @State private var userGroupIds: [String] = []
    @State private var uploadedImageUrl: String?

    var body: some View {
        VStack {
            HStack {
                HStack {
                    TextField("What's on your mind?", text: $statusText)
                        .padding()
                    
                    Button(action: {
                        self.showImagePicker = true
                    }) {
                        Image(systemName: "photo")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding()
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.gray, lineWidth: 1)
                )
                
                Button("Post") {
                    if selectedImage != nil {
                        uploadPhoto()
                    } else {
                        postStatus()
                    }
                }
                .padding()
                .background(HexColor.fromHex("CCCCFF"))
                .foregroundColor(.black)
                .cornerRadius(10)
            }

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }

            Spacer()

            if isLoading {
                ProgressView()
            } else if userGroupIds.isEmpty {
                Text("You are not in any group.")
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(groupStatuses) { status in
                            CustomListItem(status: status)
                            Divider()
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding()
        .sheet(isPresented: $showImagePicker, onDismiss: uploadPhoto) {
            ImagePicker(image: self.$selectedImage)
        }
        .onAppear(perform: fetchUserGroups)
    }

    private func uploadPhoto() {
        guard let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.75) else { return }

        let storageRef = Storage.storage().reference()
        let photoId = UUID().uuidString
        let photoRef = storageRef.child("photos/\(photoId).jpg")

        photoRef.putData(imageData, metadata: nil) { metadata, error in
            guard error == nil else {
                print("Failed to upload photo: \(error!.localizedDescription)")
                return
            }

            photoRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("Download URL not found")
                    return
                }

                self.uploadedImageUrl = downloadURL.absoluteString
                self.postStatus()
            }
        }
    }

    private func postStatus() {
        guard let groupId = userGroupIds.first else {
            print("No group ID available")
            return
        }

        let db = Firestore.firestore()
        var statusData: [String: Any] = [
            "userId": Auth.auth().currentUser?.uid ?? "Unknown",
            "text": statusText,
            "timestamp": Timestamp(date: Date()),
            "groupId": groupId
        ]

        if let imageUrl = uploadedImageUrl {
            statusData["imageUrl"] = imageUrl
        }

        db.collection("statuses").addDocument(data: statusData) { error in
            if let error = error {
                print("Error posting status: \(error)")
            } else {
                self.statusText = ""
                self.selectedImage = nil
                self.fetchGroupStatuses()
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

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
