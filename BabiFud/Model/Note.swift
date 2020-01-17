/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import CloudKit

class Note {
  private let id: CKRecord.ID
  private(set) var noteLabel: String?
  let establishmentReference: CKRecord.Reference?

  init(record: CKRecord) {
    id = record.recordID
    noteLabel = record["text"] as? String
    establishmentReference = record["establishment"] as? CKRecord.Reference
  }
  
  //this gets the notes for a specific user
  static func fetchNotes(_ completion: @escaping (Result<[Note], Error>) -> Void) {
    let query = CKQuery(recordType: "Note",
                        predicate: NSPredicate(value: true))
    let container = CKContainer.default()
    container.privateCloudDatabase
      .perform(query, inZoneWith: nil) { results, error in
        
        if let error = error {
          DispatchQueue.main.async {
            completion(.failure(error))
          }
          return
        }
          
        guard let results = results else {
          DispatchQueue.main.async {
            let error = NSError(
              domain: "com.babifud", code: -1,
              userInfo: [NSLocalizedDescriptionKey: "Could not download notes"])
            completion(.failure(error))
          }
          return
        }

        let notes = results.map(Note.init)
        DispatchQueue.main.async {
          completion(.success(notes))
        }

      
    }
  }

  // thes gets the notes for a specific establishment based on the arrray of referencess stored in the establishment - not by looking 
  static func fetchNotes(for references: [CKRecord.Reference],
                         _ completion: @escaping ([Note]) -> Void) {
    let recordIDs = references.map { $0.recordID }
    let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
    operation.qualityOfService = .utility
    
    operation.fetchRecordsCompletionBlock = { records, error in
      let notes = records?.values.map(Note.init) ?? []
      DispatchQueue.main.async {
        completion(notes)
      }
    }
    
    Model.currentModel.privateDB.add(operation)
  }

  
}

extension Note: Hashable {
  static func == (lhs: Note, rhs: Note) -> Bool {
    return lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
