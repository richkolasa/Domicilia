import Foundation
import SwiftUI
import CloudKit
import UIKit

@Observable
final class PlantImageManager {
    private let fileManager: FileManager
    private let cloudContainer: CKContainer
    private let imagesDirectory: URL
    private var syncTask: Task<Void, Never>?
    private var errorDebounceTask: Task<Void, Never>?
    var cloudError: String?
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.cloudContainer = CKContainer(identifier: "iCloud.com.richardkolasa.domicilia")
        
        // Get the documents directory
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.imagesDirectory = docs.appendingPathComponent("PlantImages", isDirectory: true)
        
        // Create images directory if it doesn't exist
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        
        // Initial sync
        checkCloudKitAvailabilityAndSync()
    }
    
    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            checkCloudKitAvailabilityAndSync()
        case .background:
            syncTask?.cancel()
        default:
            break
        }
    }
    
    private func setError(_ error: String?) {
        // Cancel any existing debounce task
        errorDebounceTask?.cancel()
        
        if let error = error {
            // For new errors, wait a bit before showing them
            errorDebounceTask = Task { @MainActor in
                do {
                    try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                    if !Task.isCancelled {
                        cloudError = error
                    }
                } catch {
                    // Ignore cancellation errors
                }
            }
        } else {
            // Clear errors immediately
            Task { @MainActor in
                cloudError = nil
            }
        }
    }
    
    private func checkCloudKitAvailabilityAndSync() {
        Task {
            do {
                print("Checking CloudKit container: \(cloudContainer.containerIdentifier ?? "no identifier")")
                
                // Check iCloud status
                let status = try await cloudContainer.accountStatus()
                print("CloudKit account status: \(status)")
                
                switch status {
                case .available:
                    // User is signed in to iCloud
                    setError(nil)
                    print("CloudKit available, attempting sync")
                    syncImages()
                case .noAccount:
                    setError("Please sign in to iCloud in Settings to sync your plant images")
                case .restricted:
                    setError("Your iCloud account is restricted")
                case .couldNotDetermine:
                    setError("Could not access iCloud. Please check your connection")
                case .temporarilyUnavailable:
                    setError("iCloud is temporarily unavailable. Please try again later")
                @unknown default:
                    setError("Unknown iCloud account status")
                }
            } catch {
                print("CloudKit error details: \(error)")
                if let ckError = error as? CKError {
                    print("CloudKit error code: \(ckError.code)")
                    print("CloudKit error description: \(ckError.localizedDescription)")
                }
                setError("Failed to check iCloud status: \(error.localizedDescription)")
            }
        }
    }
    
    private func syncImages() {
        // Cancel any existing sync task
        syncTask?.cancel()
        
        // Start new sync task
        syncTask = Task {
            do {
                print("Starting CloudKit sync")
                try await syncImagesFromCloud()
                print("CloudKit sync completed successfully")
                setError(nil)
            } catch {
                print("CloudKit sync error details: \(error)")
                if let ckError = error as? CKError {
                    print("CloudKit sync error code: \(ckError.code)")
                    print("CloudKit sync error description: \(ckError.localizedDescription)")
                    
                    switch ckError.code {
                    case .notAuthenticated:
                        setError("Please sign in to iCloud in Settings to sync your plant images")
                    case .networkFailure, .networkUnavailable:
                        setError("Network connection failed. Please check your connection")
                    case .quotaExceeded:
                        setError("iCloud storage is full. Please free up some space")
                    default:
                        setError("Failed to sync images: \(ckError.localizedDescription)")
                    }
                } else {
                    setError("Failed to sync images: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Save image locally and to CloudKit
    func saveImage(_ image: UIImage, for plant: Plant) async throws {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw ImageError.compressionFailed
        }
        
        // Generate unique filename if none exists
        let fileName = plant.imageFileName ?? "\(plant.id.uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        // Save locally
        try data.write(to: fileURL)
        
        // Save to CloudKit
        let asset = CKAsset(fileURL: fileURL)
        let record = CKRecord(recordType: "PlantImage")
        record.setValue(asset, forKey: "imageData")
        record.setValue(plant.id.uuidString, forKey: "plantId")
        
        let savedRecord = try await cloudContainer.privateCloudDatabase.save(record)
        
        // Update plant model
        plant.imageFileName = fileName
        plant.imageModificationDate = Date()
        plant.cloudImageAssetID = savedRecord.recordID.recordName
    }
    
    // Load image from local storage
    func loadImage(for plant: Plant) -> UIImage? {
        guard let fileName = plant.imageFileName else { return nil }
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    // Delete image locally and from CloudKit
    func deleteImage(for plant: Plant) async throws {
        // Delete local file
        if let fileName = plant.imageFileName {
            let fileURL = imagesDirectory.appendingPathComponent(fileName)
            try? fileManager.removeItem(at: fileURL)
        }
        
        // Delete from CloudKit using plantId
        let predicate = NSPredicate(format: "plantId == %@", plant.id.uuidString)
        let query = CKQuery(recordType: "PlantImage", predicate: predicate)
        
        let records = try await cloudContainer.privateCloudDatabase.records(matching: query)
        for record in records.matchResults.compactMap({ try? $0.1.get() }) {
            try await cloudContainer.privateCloudDatabase.deleteRecord(withID: record.recordID)
        }
        
        // Clear plant image references
        plant.imageFileName = nil
        plant.imageModificationDate = nil
        plant.cloudImageAssetID = nil
    }
    
    // Sync images from CloudKit
    func syncImagesFromCloud() async throws {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "PlantImage", predicate: predicate)
        
        var cursor: CKQueryOperation.Cursor?
        repeat {
            let (matchResults, newCursor) = try await cloudContainer.privateCloudDatabase.records(
                matching: query,
                desiredKeys: ["plantId", "imageData"]
            )
            cursor = newCursor
            
            for record in matchResults.compactMap({ try? $0.1.get() }) {
                guard let plantId = record.value(forKey: "plantId") as? String,
                      let asset = record.value(forKey: "imageData") as? CKAsset,
                      let fileURL = asset.fileURL else { continue }
                
                let fileName = "\(plantId).jpg"
                let destinationURL = imagesDirectory.appendingPathComponent(fileName)
                
                // If file already exists, only copy if it's different
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try? fileManager.removeItem(at: destinationURL)
                }
                
                try? fileManager.copyItem(at: fileURL, to: destinationURL)
            }
        } while cursor != nil
    }
    
    enum ImageError: Error {
        case compressionFailed
    }
} 
