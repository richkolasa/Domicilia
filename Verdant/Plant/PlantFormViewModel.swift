import Observation
import Foundation
import CoreData

@Observable
class PlantFormViewModel {
    var name = ""
    var notes = ""
    
    var wateringSchedule = Schedule.weekly
    var rotationSchedule = Schedule.none
    var fertilizerSchedule = Schedule.none
	
    var plant: Plant?
    
	init(plant: Plant? = nil) {
        if let plant {
            self.plant = plant
            self.name = plant.name
            self.notes = plant.notes ?? ""
			self.wateringSchedule = plant.wateringSchedule
			self.rotationSchedule = plant.rotationSchedule
			self.fertilizerSchedule = plant.fertilizationSchedule
        }
    }
	
	var hasImage: Bool = false
	
	var isValid: Bool {
		!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasImage
	}
    
	func updatePlant() {		
		if let plant = plant {
			// Update existing plant
			plant.name = name
			plant.notes = notes.isEmpty ? nil : notes
			
			
			if plant.wateringSchedule != wateringSchedule {
				plant.wateringSchedule = wateringSchedule
				if let date = wateringSchedule.nextDate() {
					plant.nextWateringDate = date
				}
			}
			
			if plant.rotationSchedule != rotationSchedule {
				plant.rotationSchedule = rotationSchedule
				if let date = rotationSchedule.nextDate() {
					plant.nextRotationDate = date
				}
			}
			
			if plant.fertilizationSchedule != fertilizerSchedule {
				plant.fertilizationSchedule = fertilizerSchedule
				if let date = fertilizerSchedule.nextDate() {
					plant.nextFertilizationDate = date
				}
			}			
		}
	}
	
	func createPlant() -> Plant {
		let now = Date()

		// Create new plant
		let plant = Plant(
			name: name,
			wateringSchedule: wateringSchedule,
			lastWateredDate: now,
			nextWateringDate: wateringSchedule.nextDate() ?? now,
			rotationSchedule: rotationSchedule,
			lastRotatedDate: rotationSchedule != .none ? now : nil,
			nextRotationDate: rotationSchedule.nextDate(),
			fertilizationSchedule: fertilizerSchedule,
			lastFertilizedDate: fertilizerSchedule != .none ? now : nil,
			nextFertilizationDate: fertilizerSchedule.nextDate(),
			notes: notes
		)
		return plant
	}
} 
