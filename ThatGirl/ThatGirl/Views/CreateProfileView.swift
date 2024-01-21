//
//  CreateProfileView.swift
//  ThatGirl
//
//  Created by Nyaradzo Bere on 1/20/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct CreateProfileView: View {
    @EnvironmentObject var sessionStore: SessionStore

    @State private var name: String = ""
    @State private var sex: String = ""
    @State private var genderIdentity: String = ""
    @State private var bio: String = ""
    @State private var inputImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var navigateToSwipeableView: Bool = false

    var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                LogoutLink()
                    .offset(y: -100)
                    .offset(x: -15)
                
                TextField("Name", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .font(Font.system(size: 16, weight: .light, design: .default))
                
                HStack(spacing: 20) {
                    VStack {
                        Text("Sex:")
                            .font(Font.system(size: 16, weight: .light, design: .default))
                        Picker("Select Sex", selection: $sex) {
                            Text("Select...").tag("")
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                        }.pickerStyle(MenuPickerStyle())
                    }
                    Spacer()
                    
                    VStack {
                        Text("Gender Identity:")
                            .font(Font.system(size: 16, weight: .light, design: .default))
                        Picker("Select Gender Identity", selection: $genderIdentity) {
                            Text("Select...").tag("")
                            Text("Man").tag("Man")
                            Text("Woman").tag("Woman")
                            Text("Non-binary").tag("Non-binary")
                        }.pickerStyle(MenuPickerStyle())
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                TextField("Bio", text: $bio)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .font(Font.system(size: 16, weight: .light, design: .default))
                
                if let image = inputImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                } else {
                    Text("No profile picture selected")
                        .font(Font.system(size: 14, weight: .light, design: .default))
                }
                
                Button("Select Profile Picture") {
                    showImagePicker = true
                }
                .padding()
                .foregroundColor(Color.black)
                .cornerRadius(8)
                .offset(x: -15)
                
                Divider().overlay(.black)
                
                Button("Save Profile", action: saveProfile)
                    .padding()
                    .foregroundColor(Color.black)
                    .offset(x: -15)
                NavigationLink(destination: DailyChecklistView()) {
                    Text("Go To Checklist")
                }
            }
            .padding(.horizontal, 40)
            .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
    }
    
    func allFieldsValid() -> Bool {
        return !name.isEmpty && !sex.isEmpty && !genderIdentity.isEmpty && !bio.isEmpty && inputImage != nil
    }
    
    func loadImage() {
        guard let _ = inputImage else { return }
        // You can process the image (if needed) or directly upload it to Firebase Storage
    }
    
    func saveProfile() {
        if !allFieldsValid() {
            alertMessage = "Please fill out all fields and select a profile picture before saving."
            showAlert = true
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let email = Auth.auth().currentUser?.email else { return }
        guard let image = inputImage else { return }

        // First, upload the image
        uploadImage(image) { url, error in
            if let error = error {
                print("Error uploading image: \(error)")
                alertMessage = "Error uploading profile picture. Please try again."
                showAlert = true
                return
            }

            guard let profileImageURL = url else {
                alertMessage = "Error getting profile picture URL. Please try again."
                showAlert = true
                return
            }
            
            let initialChecklist: [[String: Any]] = [
                ["taskName": "Wake Up Before 10am", "isCompleted": false, "points": 10],
                ["taskName": "Oil Pull", "isCompleted": false, "points": 5],
                ["taskName": "Double Cleanse", "isCompleted": false, "points": 5],
                ["taskName": "Apply Sunscreen", "isCompleted": false, "points": 5],
                ["taskName": "Morning Meditation", "isCompleted": false, "points": 15],
                ["taskName": "30 Minutes of Exercise", "isCompleted": false, "points": 20],
                ["taskName": "Protein Filled Breakfast", "isCompleted": false, "points": 15],
                ["taskName": "10 Minute Journaling", "isCompleted": false, "points": 10],
                ["taskName": "Read a Book", "isCompleted": false, "points": 10],
                ["taskName": "Drink 1/2 Gallon of Water", "isCompleted": false, "points": 15],
                ["taskName": "Write Today's Goals", "isCompleted": false, "points": 10],
                ["taskName": "Read Before Bed", "isCompleted": false, "points": 10]
            ]

            let db = Firestore.firestore()
            let docRef = db.collection("users").document(uid)

            let values: [String: Any] = [
                "email": email,
                "name": name,
                "sex": sex,
                "genderIdentity": genderIdentity,
                "bio": bio,
                "profilePictureUrl": profileImageURL.absoluteString,
                "dailyChecklist": initialChecklist 
            ]

            docRef.setData(values) { error in
                if let error = error {
                    print("Error writing document: \(error)")
                    alertMessage = "Error saving profile. Please try again."
                    showAlert = true
                } else {
                    alertMessage = "Profile successfully saved!"
                    showAlert = true
                    print("Attempting to navigate to SwipeableView...")
                    self.navigateToSwipeableView = true
                }
            }
        }
    }

    func uploadImage(_ image: UIImage, completion: @escaping (_ url: URL?, _ error: Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "FirebaseAuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve user ID"]))
            return
        }

        let storage = Storage.storage().reference().child("profilePictures").child("\(uid).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(nil, NSError(domain: "ImageError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]))
            return
        }

        storage.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(nil, error)
                return
            }

            storage.downloadURL { url, error in
                completion(url, error)
            }
        }
    }
}

struct CreateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CreateProfileView()
    }
}
