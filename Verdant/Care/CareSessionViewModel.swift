import Observation
import Foundation
import SwiftUI

@Observable
class CareSessionViewModel {
    var plants: [Plant]
    var currentIndex = 0
    var completedTasks: Set<CareTask> = []
    
    var currentPlant: Plant {
        plants[currentIndex]
    }
    
    var allTasks: [CareTask] {
        var tasks: [CareTask] = []
        for plant in plants {
            if plant.needsWatering {
                tasks.append(CareTask(type: .watering, plantName: plant.name))
            }
            if plant.needsRotation {
                tasks.append(CareTask(type: .rotation, plantName: plant.name))
            }
			if plant.needsFertilizing {
				tasks.append(CareTask(type: .fertilizing, plantName: plant.name))
			}
        }
        return tasks
    }
    
    var isComplete: Bool {
        let wateringComplete = !currentPlant.needsWatering || completedTasks.contains(CareTask(type: .watering, plantName: currentPlant.name))
        let rotationComplete = !currentPlant.needsRotation || completedTasks.contains(CareTask(type: .rotation, plantName: currentPlant.name))
        let fertilizingComplete = !currentPlant.needsFertilizing || completedTasks.contains(CareTask(type: .fertilizing, plantName: currentPlant.name))
        
        return wateringComplete && rotationComplete && fertilizingComplete
    }
    
    init(plants: [Plant]) {
		self.plants = plants.filter { $0.needsWatering || $0.needsRotation || $0.needsFertilizing }
    }
    
    func completeTask(_ task: CareTask) {
        let now = Date()
        
		switch task.type {
        case .watering:
            currentPlant.lastWateredDate = now
			if let nextDate = currentPlant.wateringSchedule.nextDate() {
                currentPlant.nextWateringDate = nextDate
            }
            
        case .rotation:
            currentPlant.lastRotatedDate = now
			if let nextDate = currentPlant.rotationSchedule.nextDate() {
                currentPlant.nextRotationDate = nextDate
            }
			
		case .fertilizing:
			currentPlant.lastFertilizedDate = now
			if let nextDate = currentPlant.fertilizationSchedule.nextDate() {
				currentPlant.nextFertilizationDate = nextDate
			}
        }
		
		completedTasks.insert(task)

		// Only start advancing if all tasks are complete and we're not already advancing
		if isComplete && hasNextPlant {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    self.advanceToNextPlant()
                }
            }
        }
    }
    
    var hasNextPlant: Bool {
        currentIndex < plants.count - 1
    }
    
    func advanceToNextPlant() {
        guard hasNextPlant else { return }
        currentIndex += 1
    }
} 
