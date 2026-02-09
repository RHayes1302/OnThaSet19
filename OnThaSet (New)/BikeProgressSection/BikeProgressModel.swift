//
//  BikeProgressModel.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import Foundation
import SwiftData

@Model
class BikeProgress {
    var id: UUID
    var createdAt: Date
    var modificationTitle: String
    var note: String
    var beforeImage: String  // Filename
    var afterImage: String   // Filename
    
    // Bike details
    var bikeMake: String
    var bikeModel: String
    var bikeYear: String
    
    // 🆕 Track who posted this bike progress
    var userID: String = ""  // Apple User ID of the person who posted
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        modificationTitle: String,
        note: String,
        beforeImage: String,
        afterImage: String,
        bikeMake: String = "",
        bikeModel: String = "",
        bikeYear: String = "",
        userID: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.modificationTitle = modificationTitle
        self.note = note
        self.beforeImage = beforeImage
        self.afterImage = afterImage
        self.bikeMake = bikeMake
        self.bikeModel = bikeModel
        self.bikeYear = bikeYear
        self.userID = userID
    }
}
