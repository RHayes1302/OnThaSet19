//
//  EventCategory.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//

import Foundation
import SwiftUI

enum EventCategory: String, CaseIterable, Codable, Hashable {

    // EXISTING
    case community      = "Community"
    case charity        = "Charity Event / Fundraiser"
    case weeklyClubhouse = "Weekly Clubhouse"

    // NEW CATEGORIES
    case bikeNight      = "Bike Night"
    case rally          = "Motorcycle Rally"
    case mcAnnual       = "MC Annual"
    case scAnnual       = "Social Club Annual"
    case rcAnnual       = "Riding Club Annual"
    case unityRun       = "Unity Run"

    var displayName: String { rawValue }

    // ICON for each category
    var icon: String {
        switch self {
        case .community:       return "🤝"
        case .charity:         return "❤️"
        case .weeklyClubhouse: return "🏠"
        case .bikeNight:       return "🏍️"
        case .rally:           return "🎪"
        case .mcAnnual:        return "🎉"
        case .scAnnual:        return "🌹"
        case .rcAnnual:        return "🚦"
        case .unityRun:        return "🤝"
        }
    }

    // Whether this category shows on the National Run Calendar map
    var isNationalEvent: Bool {
        switch self {
        case .rally, .charity, .mcAnnual, .scAnnual, .rcAnnual, .unityRun:
            return true
        default:
            return false
        }
    }

    // Pin color on national map
    var mapPinColor: String {
        switch self {
        case .rally:    return "red"
        case .charity:  return "blue"
        case .mcAnnual: return "yellow"
        case .scAnnual: return "pink"
        case .rcAnnual: return "green"
        case .unityRun: return "purple"
        default:        return "gray"
        }
    }
}

enum AnnualsSubCategory: String, CaseIterable, Codable, Hashable {
    case outlaws    = "Outlaws (1%)"
    case mc99       = "Motorcycle Clubs (99%)"
    case femaleSocial = "Female Social Clubs"
    case none       = "None"
    var displayName: String { rawValue }
}

enum EventStatus: String, CaseIterable, Codable, Hashable {
    case partyStillOn = "Party Still On"
    case cancelled    = "Cancelled"
    var displayName: String { rawValue }
}
