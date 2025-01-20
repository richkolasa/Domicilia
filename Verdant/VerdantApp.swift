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
	@State private var notificationManager: NotificationManager
	@State private var plantManager: PlantManager
	
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
	
	init() {
		let context = sharedModelContainer.mainContext
		_notificationManager = State(initialValue: NotificationManager(modelContext: context))
		_plantManager = State(initialValue: PlantManager(modelContext: context))
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(weatherManager)
				.environment(settingsCoordinator)
				.environment(notificationManager)
				.environment(plantManager)
				.modelContainer(sharedModelContainer)
				.fontDesign(.rounded)
		}
		.onChange(of: scenePhase) { _, newPhase in
			plantManager.handleScenePhaseChange(newPhase)
		}
	}
}
