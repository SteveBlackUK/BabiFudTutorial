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

import UIKit
import MapKit
import CloudKit
import CoreLocation

class Establishment {
  enum ChangingTable: Int {
    case none
    case womens
    case mens
    case both
  }
  
  static let recordType = "Establishment"
  let id: CKRecord.ID
  let name: String
  let location: CLLocation
  let coverPhoto: CKAsset?
  let database: CKDatabase
  let changingTable: ChangingTable
  let kidsMenu: Bool
  let healthyOption: Bool
  private(set) var notes: [Note]? = nil
  
  init?(record: CKRecord, database: CKDatabase) {
    guard
      let name = record["name"] as? String,
      let location = record["location"] as? CLLocation
      else { return nil }
    id = record.recordID
    self.name = name
    self.location = location
    coverPhoto = record["coverPhoto"] as? CKAsset
    self.database = database
    healthyOption = record["healthyOption"] as? Bool ?? false
    kidsMenu = record["kidsMenu"] as? Bool ?? false
    if let changingTableValue = record["changingTable"] as? Int,
      let changingTable = ChangingTable(rawValue: changingTableValue) {
      self.changingTable = changingTable
    } else {
      self.changingTable = .none
    }
    //checks to see if the establisthment has an arrah of references and if so, only load thos specific ones
    if let noteRecords = record["notes"] as? [CKRecord.Reference] {
      Note.fetchNotes(for: noteRecords) { notes in
        self.notes = notes
      }
    }

  }
  
    
  func loadCoverPhoto(completion: @escaping (_ photo: UIImage?) -> ()) {
    // 1.
    DispatchQueue.global(qos: .utility).async {
      var image: UIImage?
      // 5.
      defer {
        DispatchQueue.main.async {
          completion(image)
        }
      }
      // 2.
      guard
        let coverPhoto = self.coverPhoto,
        let fileURL = coverPhoto.fileURL
        else {
          return
      }
      let imageData: Data
      do {
        // 3.
        imageData = try Data(contentsOf: fileURL)
      } catch {
        return
      }
      // 4.
      image = UIImage(data: imageData)
    }
  }
}


extension Establishment: Hashable {
  static func == (lhs: Establishment, rhs: Establishment) -> Bool {
    return lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
