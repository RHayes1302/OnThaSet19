//
//  EventPhotoModel.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import Foundation
import SwiftData

@Model
class EventPhoto {
    var id: UUID
    var createdAt: Date
    var eventName: String
    var eventDate: Date
    var location: String
    var caption: String
    var photoFileName: String
    
    // 🆕 Track who posted the photo
    var userID: String = ""  // Apple User ID of the person who posted
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        eventName: String,
        eventDate: Date,
        location: String,
        caption: String,
        photoFileName: String,
        userID: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.eventName = eventName
        self.eventDate = eventDate
        self.location = location
        self.caption = caption
        self.photoFileName = photoFileName
        self.userID = userID
    }
}
