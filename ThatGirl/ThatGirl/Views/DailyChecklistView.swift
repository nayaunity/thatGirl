//
//  DailyChecklistView.swift
//  ThatGirl
//
//  Created by Nyaradzo Bere on 1/20/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore

struct DailyChecklistView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var checklist: [ChecklistItem] = []
    
    // Function to get current date as a String
    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d" // Example: "Monday, January 20"
        return dateFormatter.string(from: Date())
    }

    var body: some View {
        VStack {
            Text(getCurrentDateString())
                .font(.title)
                .padding()
            List($checklist) { $item in
                HStack {
                    Text(item.taskName)
                    Spacer()
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .onTapGesture {
                            toggleTaskCompletion(item)
                        }
                }
            }
        }
        .onAppear(perform: loadChecklist)
    }

    func loadChecklist() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let data = document.data(), let checklistData = data["dailyChecklist"] as? [[String: Any]] {
                    self.checklist = checklistData.map { ChecklistItem(dictionary: $0) }
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    func toggleTaskCompletion(_ item: ChecklistItem) {
        guard let index = checklist.firstIndex(where: { $0.id == item.id }) else { return }

        checklist[index].isCompleted.toggle() // Update local state
        updateChecklistInFirestore() // Update Firestore
    }

    func updateChecklistInFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)

        // Convert the entire updated checklist to dictionary format
        let updatedChecklist = checklist.map { $0.dictionaryRepresentation }

        // Replace the entire 'dailyChecklist' field in Firestore
        docRef.updateData(["dailyChecklist": updatedChecklist]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }


    func updateChecklistInFirestore(_ item: ChecklistItem) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)

        // Assuming `dailyChecklist` is stored as an array in Firestore
        docRef.updateData([
            "dailyChecklist": FieldValue.arrayUnion([item.dictionaryRepresentation])
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
}

struct ChecklistItem: Identifiable {
    var id: String = UUID().uuidString
    var taskName: String
    var isCompleted: Bool
    var points: Int

    init(dictionary: [String: Any]) {
        self.taskName = dictionary["taskName"] as? String ?? ""
        self.isCompleted = dictionary["isCompleted"] as? Bool ?? false
        self.points = dictionary["points"] as? Int ?? 0
    }

    var dictionaryRepresentation: [String: Any] {
        return ["taskName": taskName, "isCompleted": isCompleted, "points": points]
    }
}

struct DailyChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        DailyChecklistView()
    }
}
