//
//  VerdantApp.swift
//  Verdant
//
//  Created by Richard Kolasa on 11/28/24.
//

import SwiftUI
import SwiftData

@main
struct VerdantApp: App {
	@Environment(\.scenePhase) private var scenePhase
	@State private var weatherManager = WeatherManager()
	@State private var settingsCoordinator = SettingsCoordinator()
	@State private var notificationManager: NotificationManager?
	@State private var imageManager = PlantImageManager()
	
	
	var sharedModelContainer: ModelContainer = {
		let schema = Schema([
			Plant.self,
		])
		let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

		do {
			return try ModelContainer(for: schema, configurations: [modelConfiguration])
		} catch {
			fatalError("Could not create ModelContainer: \(error)")
		}
	}()
	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(weatherManager)
				.environment(settingsCoordinator)
				.environment(imageManager)
				.modelContainer(sharedModelContainer)
				.onAppear {
					if notificationManager == nil {
						notificationManager = NotificationManager(modelContext: sharedModelContainer.mainContext)
					}
				}
				.fontDesign(.rounded)
		}
		.onChange(of: scenePhase) { _, newPhase in
			imageManager.handleScenePhaseChange(newPhase)
		}
	}
}
