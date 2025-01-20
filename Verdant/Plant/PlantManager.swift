//import Foundation
//import SwiftData
//
//@Observable
//class PlantManager {
//    private let modelContext: ModelContext
//    private let calendar = Calendar.current
//    
//    init(modelContext: ModelContext) {
//        self.modelContext = modelContext
//    }
//    
//    func updatePlantStatuses() {
//        let descriptor = FetchDescriptor<Plant>()
//        guard let plants = try? modelContext.fetch(descriptor) else { return }
//        
//        let today = calendar.startOfDay(for: Date())
//        
//        for plant in plants {
//            // Check watering status
//            let wateringDate = calendar.startOfDay(for: plant.nextWateringDate)
//            if today >= wateringDate && !plant.needsWatering {
//                plant.needsWatering = true
//            }
//            
//            // Check rotation status
//            if let nextRotation = plant.nextRotationDate {
//                let rotationDate = calendar.startOfDay(for: nextRotation)
//                if today >= rotationDate && !plant.needsRotation {
//                    plant.needsRotation = true
//                }
//            }
//        }
//        
//        try? modelContext.save()
//    }
//} 
