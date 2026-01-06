//
//  BodyLocation.swift
//  OmniSiteTracker
//
//  Strongly-typed enum representing valid insulin pump placement sites.
//

import Foundation

/// Represents all valid body locations for insulin pump placement.
/// Each case corresponds to a medically-approved site for pump insertion.
enum BodyLocation: String, Codable, CaseIterable, Identifiable {
    case leftArm = "left_arm"
    case rightArm = "right_arm"
    case abdomenLeft = "abdomen_left"
    case abdomenRight = "abdomen_right"
    case lowerAbdomen = "lower_abdomen"
    case leftThigh = "left_thigh"
    case rightThigh = "right_thigh"
    case lowerBack = "lower_back"

    var id: String { rawValue }

    /// Human-readable display name for the body location
    var displayName: String {
        switch self {
        case .leftArm:
            return "Left Arm (Back)"
        case .rightArm:
            return "Right Arm (Back)"
        case .abdomenLeft:
            return "Abdomen (Left)"
        case .abdomenRight:
            return "Abdomen (Right)"
        case .lowerAbdomen:
            return "Lower Abdomen"
        case .leftThigh:
            return "Left Thigh"
        case .rightThigh:
            return "Right Thigh"
        case .lowerBack:
            return "Lower Back"
        }
    }

    /// Short display name for compact UI elements
    var shortName: String {
        switch self {
        case .leftArm:
            return "L. Arm"
        case .rightArm:
            return "R. Arm"
        case .abdomenLeft:
            return "L. Abdomen"
        case .abdomenRight:
            return "R. Abdomen"
        case .lowerAbdomen:
            return "Low. Abdomen"
        case .leftThigh:
            return "L. Thigh"
        case .rightThigh:
            return "R. Thigh"
        case .lowerBack:
            return "Low. Back"
        }
    }

    /// Label for the body diagram zones - concise but readable
    var zoneLabel: String {
        switch self {
        case .leftArm:
            return "Left\nArm"
        case .rightArm:
            return "Right\nArm"
        case .abdomenLeft:
            return "Left\nAbdomen"
        case .abdomenRight:
            return "Right\nAbdomen"
        case .lowerAbdomen:
            return "Lower Abdomen"
        case .leftThigh:
            return "Left\nThigh"
        case .rightThigh:
            return "Right\nThigh"
        case .lowerBack:
            return "Lower Back"
        }
    }

    /// SF Symbol icon representing the body location
    var iconName: String {
        switch self {
        case .leftArm, .rightArm:
            return "hand.raised.fill"
        case .abdomenLeft, .abdomenRight, .lowerAbdomen:
            return "circle.fill"
        case .leftThigh, .rightThigh:
            return "figure.stand"
        case .lowerBack:
            return "rectangle.fill"
        }
    }

    /// Whether this location is on the front of the body (for diagram display)
    var isFrontView: Bool {
        switch self {
        case .abdomenLeft, .abdomenRight, .lowerAbdomen, .leftThigh, .rightThigh:
            return true
        case .leftArm, .rightArm, .lowerBack:
            return false
        }
    }

    /// Returns the opposite side location if applicable (for rotation suggestions)
    var oppositeSide: BodyLocation? {
        switch self {
        case .leftArm:
            return .rightArm
        case .rightArm:
            return .leftArm
        case .abdomenLeft:
            return .abdomenRight
        case .abdomenRight:
            return .abdomenLeft
        case .leftThigh:
            return .rightThigh
        case .rightThigh:
            return .leftThigh
        case .lowerAbdomen, .lowerBack:
            return nil
        }
    }
}
