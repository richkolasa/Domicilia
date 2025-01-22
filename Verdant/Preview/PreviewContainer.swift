import SwiftUI
import SwiftData

@MainActor
struct PreviewContainer {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    let plantManager: PlantManager
    
    static let shared = PreviewContainer()
    
    init() {
        let schema = Schema([Plant.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
            plantManager = PlantManager(modelContext: modelContext)
            
            // Add sample data
            let plant1 = Plant(
                name: "Monstera",
                wateringSchedule: .weekly,
                lastWateredDate: .now,
                nextWateringDate: .now.addingTimeInterval(7 * 24 * 60 * 60),
                rotationSchedule: .biweekly,
                lastRotatedDate: .now,
                nextRotationDate: .now.addingTimeInterval(14 * 24 * 60 * 60),
                fertilizationSchedule: .monthly,
                lastFertilizedDate: .now,
                nextFertilizationDate: .now.addingTimeInterval(30 * 24 * 60 * 60),
                notes: "Loves bright indirect light"
            )
            
            let plant2 = Plant(
                name: "Snake Plant",
                wateringSchedule: .biweekly,
                lastWateredDate: .now,
                nextWateringDate: .now.addingTimeInterval(14 * 24 * 60 * 60),
                rotationSchedule: .none,
                lastRotatedDate: nil,
                nextRotationDate: nil,
                fertilizationSchedule: .none,
                lastFertilizedDate: nil,
                nextFertilizationDate: nil,
                notes: "Very low maintenance"
            )
            
            modelContext.insert(plant1)
            modelContext.insert(plant2)
            
        } catch {
            fatalError("Could not create preview container: \(error.localizedDescription)")
        }
    }
}

extension View {
    func previewWith(_ container: PreviewContainer = .shared) -> some View {
        self
            .modelContainer(container.modelContainer)
            .environment(container.plantManager)
    }
} 