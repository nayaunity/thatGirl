//
//  FeedView.swift
//  ThatGirl
//
//  Created by Nyaradzo Bere on 1/20/24.
//

import Foundation
import SwiftUI

struct FeedView: View {
    @State private var statusText: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var selectedImage: Image?

    var body: some View {
        VStack {
            // Status Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Share your status:")
                    .font(.headline)

                TextField("What's on your mind?", text: $statusText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                HStack {
                    Button(action: {
                        // Present image picker
                        isImagePickerPresented.toggle()
                    }) {
                        Image(systemName: "photo")
                            .font(.headline)
                        Text("Photo")
                            .font(.headline)
                    }

                    Spacer()

                    Button(action: {
                        // Add functionality to post the status here
                        // You can use the `statusText` and `selectedImage` variables
                        // to post text and images
                    }) {
                        Text("Post")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)
            Spacer()

            // Add more feed content here
        }
        .padding()
        .sheet(isPresented: $isImagePickerPresented) {
            // Present an image picker to select images
            // You can handle image selection and update the `selectedImage` variable here
        }
    }
}

struct FeedView_Preview: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}

