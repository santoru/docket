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

    var icon: String {
        switch self {
        case .doFirst: "flame"
        case .schedule: "calendar"
        case .delegate: "person.2"
        case .eliminate: "trash"
        }
    }
}
