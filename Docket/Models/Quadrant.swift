// Quadrant.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Eisenhower Matrix quadrant.
enum Quadrant: Int, Codable, CaseIterable, Identifiable {
    case doFirst = 0    // Urgent + Important
    case schedule = 1   // Not Urgent + Important
    case delegate = 2   // Urgent + Not Important
    case eliminate = 3  // Not Urgent + Not Important

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .doFirst: "Do First"
        case .schedule: "Schedule"
        case .delegate: "Delegate"
        case .eliminate: "Eliminate"
        }
    }

    var color: Color {
        switch self {
        case .doFirst: Color(red: 0.94, green: 0.27, blue: 0.27)
        case .schedule: Color(red: 0.23, green: 0.51, blue: 0.96)
        case .delegate: Color(red: 0.96, green: 0.62, blue: 0.04)
        case .eliminate: Color(red: 0.61, green: 0.64, blue: 0.69)
        }
    }

    var icon: String {
        switch self {
        case .doFirst: "flame"
        case .schedule: "calendar"
        case .delegate: "person.2"
        case .eliminate: "trash"
        }
    }
}
