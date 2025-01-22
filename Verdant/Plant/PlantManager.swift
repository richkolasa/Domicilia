import Foundation
import SwiftUI
import CloudKit
import SwiftData

@MainActor
@Observable
final class PlantManager {
    private let imageManager: PlantImageManager
    private let modelContext: ModelContext
    var isSaving = false
	
    init(modelContext: ModelContext, imageManager: PlantImageManager = PlantImageManager()) {
        self.modelContext = modelContext
        self.imageManager = imageManager
    }
    
    // MARK: - Plant Management
    
    func addPlant(_ plant: Plant, image: UIImage? = nil) async throws {
		isSaving = true
        if let image = image {
            try await imageManager.saveImage(image, for: plant)
        }
        modelContext.insert(plant)
		try modelContext.save()
		isSaving = false
    }
    
    func updatePlant(_ plant: Plant, image: UIImage? = nil) async throws {
		isSaving = true
        if let image = image {
            try await imageManager.saveImage(image, for: plant)
        }
		isSaving = false
    }
    
    func deletePlant(_ plant: Plant) async throws {
        try await imageManager.deleteImage(for: plant)
        modelContext.delete(plant)
		try modelContext.save()
    }
    
    // MARK: - Image Management
    
    func loadImage(for plant: Plant) -> UIImage? {
        imageManager.loadImage(for: plant)
    }
    
    func handleScenePhaseChange(_ phase: ScenePhase) {
        imageManager.handleScenePhaseChange(phase)
    }
    
    var cloudError: String? {
        imageManager.cloudError
    }
} 
