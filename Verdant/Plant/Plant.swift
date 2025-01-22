//
//  Plant.swift
//  Verdant
//
//  Created by Richard Kolasa on 11/30/24.
//

import Foundation
import UIKit
import SwiftData

@Model
final class Plant {
//	@Attribute(.unique)
	var id: UUID = UUID()
	var name: String = ""
	
	// Image handling
	var imageFileName: String?
	var imageModificationDate: Date?
	var cloudImageAssetID: String?
	
	// Watering properties
	var wateringSchedule: Schedule = Schedule.weekly
	var lastWateredDate: Date = Date()
	var nextWateringDate: Date = Date().addingTimeInterval(86400 * 7)
	
	// Rotation properties
	var rotationSchedule: Schedule = Schedule.none
	var lastRotatedDate: Date?
	var nextRotationDate: Date?
	
	// Fertilizing Schedule
	var fertilizationSchedule: Schedule = Schedule.none
	var lastFertilizedDate: Date?
	var nextFertilizationDate: Date?
	
	// Additional care info
	var notes: String?
	
	var nextCareDate: Date {
		if let nextRotation = nextRotationDate {
			return min(nextWateringDate, nextRotation)
		}
		return nextWateringDate
	}
	
	var needsWatering: Bool {
		return Calendar.current.isDateInToday(nextWateringDate) || nextWateringDate < Date()
	}
	
	var needsRotation: Bool {
		guard rotationSchedule != .none else {
			return false
		}
		guard let nextRotationDate else {
			return false
		}
		return Calendar.current.isDateInToday(nextRotationDate) || nextRotationDate < Date()
	}
	
	var needsFertilizing: Bool {
		guard fertilizationSchedule != .none else {
			return false
		}
		guard let nextFertilizationDate else {
			return false
		}
		return Calendar.current.isDateInToday(nextFertilizationDate) || nextFertilizationDate < Date()
	}
	
	init(
		id: UUID = UUID(),
		name: String,
		wateringSchedule: Schedule,
		lastWateredDate: Date,
		nextWateringDate: Date,
		rotationSchedule: Schedule,
		lastRotatedDate: Date?,
		nextRotationDate: Date?,
		fertilizationSchedule: Schedule,
		lastFertilizedDate: Date?,
		nextFertilizationDate: Date?,
		notes: String?
	) {
		self.id = id
		self.name = name
		self.wateringSchedule = wateringSchedule
		self.lastWateredDate = lastWateredDate
		self.nextWateringDate = nextWateringDate
		self.rotationSchedule = rotationSchedule
		self.lastRotatedDate = lastRotatedDate
		self.nextRotationDate = nextRotationDate
		self.fertilizationSchedule = fertilizationSchedule
		self.lastFertilizedDate = lastFertilizedDate
		self.nextFertilizationDate = nextFertilizationDate
		self.notes = notes
	}
	
	enum LightLevel: String, CaseIterable, Codable {
		case low = "Low Light"
		case medium = "Medium Light"
		case bright = "Bright Indirect"
		case direct = "Direct Sunlight"
	}
}

// Example of creating a plant:
extension Plant {
	static var example: Plant {
		Plant(
			name: "Fiddle Leaf Fig",
			wateringSchedule: .weekly,
			lastWateredDate: Date().addingTimeInterval(-86400 * 5),
			nextWateringDate: Date().addingTimeInterval(86400 * 2),
			rotationSchedule: .monthly,
			lastRotatedDate: Date().addingTimeInterval(-86400 * 20),
			nextRotationDate: Date().addingTimeInterval(86400 * 10),
			fertilizationSchedule: .monthly,
			lastFertilizedDate: Date().addingTimeInterval(-86400 * 10),
			nextFertilizationDate: Date().addingTimeInterval(86400 * 10),
			notes: "Likes to be near the window but not in direct sunlight"
		)
	}
}

enum Schedule: String, Codable {
	case none = "None"
	case daily = "Daily"
	case weekly = "Weekly"
	case biweekly = "Every 2 Weeks"
	case monthly = "Monthly"
	
	func nextDate(from date: Date = Date()) -> Date? {
		let calendar = Calendar.current
		let startOfDay = calendar.startOfDay(for: date)
		
		switch self {
		case .none:
			return nil
		case .daily:
			return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
		case .weekly:
			return calendar.date(byAdding: .weekOfYear, value: 1, to: startOfDay) ?? startOfDay
		case .biweekly:
			return calendar.date(byAdding: .weekOfYear, value: 2, to: startOfDay) ?? startOfDay
		case .monthly:
			return calendar.date(byAdding: .month, value: 1, to: startOfDay) ?? startOfDay
		}
	}
}
