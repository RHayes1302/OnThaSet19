//
//  EventLayout.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//

import Foundation
import SwiftData
import UIKit

@Model
class Event {
    var title: String
    var date: Date
    var category: EventCategory
    var locationName: String
    var details: String
    var securityCode: String
    var price: String
    
    var isFavorite: Bool = false
    
    @Attribute(.externalStorage) var imageData: Data?
    var latitude: Double
    var longitude: Double
    
    // 🆕 Track who posted the event
    var postedByUserID: String = "" // Apple User ID of the person who posted
    var postedByName: String = "" // Display name of the person who posted
    var postedDate: Date = Date() // When it was posted
    
    init(
        title: String = "",
        date: Date = Date(),
        category: EventCategory = .community,
        locationName: String = "",
        details: String = "",
        securityCode: String = "",
        price: String = "3.00",
        isFavorite: Bool = false,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        postedByUserID: String = "",
        postedByName: String = ""
    ) {
        self.title = title
        self.date = date
        self.category = category
        self.locationName = locationName
        self.details = details
        self.securityCode = securityCode
        self.price = price
        self.isFavorite = isFavorite
        self.latitude = latitude
        self.longitude = longitude
        self.postedByUserID = postedByUserID
        self.postedByName = postedByName
        self.postedDate = Date()
    }
    
    // Helper for displaying the image
    var image: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
}
