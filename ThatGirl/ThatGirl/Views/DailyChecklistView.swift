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
    @State private var totalPoints: Int = 0

    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        return dateFormatter.string(from: Date())
    }

    private func calculateTotalPoints() {
        totalPoints = checklist.reduce(0) { $0 + ($1.isCompleted ? $1.points : 0) }
    }

    var body: some View {
        VStack {
            LogoutLink()
                .offset(y: -50)
                .offset(x: -150)
            Text(getCurrentDateString())
                .font(.title)
                .fontWeight(.light)
                .padding(.top)

            Text("Points: \(totalPoints)")
                .font(.title2)
                .padding(.bottom)

            List($checklist.indices, id: \.self) { index in
                HStack {
                    Text(checklist[index].taskName)
                        .font(.headline)
                        .padding(.vertical, 8)
                    Spacer()
                    Image(systemName: checklist[index].isCompleted ? "checkmark.circle.fill" : "circle")
                        .imageScale(.large)
                        .foregroundColor(checklist[index].isCompleted ? HexColor.fromHex("A888FF") : HexColor.fromHex("CCCCFF"))
                        .onTapGesture {
                            toggleTaskCompletion(index)
                        }
                }
                .padding(.horizontal)
                .background(RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(checklist[index].isCompleted ? HexColor.fromHex("CCCCFF").opacity(0.3) : Color.white))
            }
            .listStyle(PlainListStyle())
        }
        .navigationBarHidden(true)
        .padding()
        .onAppear(perform: loadChecklist)
    }

    private func loadChecklist() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let data = document.data(), let checklistData = data["dailyChecklist"] as? [[String: Any]] {
                    self.checklist = checklistData.map { ChecklistItem(dictionary: $0) }
                    self.calculateTotalPoints() // Calculate points after loading checklist
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    func toggleTaskCompletion(_ index: Int) {
        checklist[index].isCompleted.toggle()
        updateChecklistInFirestore()
        calculateTotalPoints()
    }

    private func updateChecklistInFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)

        let updatedChecklist = checklist.map { $0.dictionaryRepresentation }
        docRef.updateData(["dailyChecklist": updatedChecklist]) { err in
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
