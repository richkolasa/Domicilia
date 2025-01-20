import SwiftUI
import SwiftData
import WeatherKit

struct ContentView: View {
	@Environment(\.horizontalSizeClass) var horizontalSizeClass
	@Environment(WeatherManager.self) var weatherManager
	@Environment(SettingsCoordinator.self) var settings
	@Environment(PlantImageManager.self) private var imageManager
	
	@Query var plants: [Plant]

	private var sortedPlants: [Plant] {
		return Array(plants.sorted { first, second in
			let firstDate = first.nextCareDate
			let secondDate = second.nextCareDate
			
			// Then sort by earliest next care date
			if firstDate != secondDate {
				return firstDate < secondDate
			}
			
			// Finally sort by name
			return first.name < second.name
		})
	}
	
	@State private var isAddingPlant = false
	@State private var isCaringForPlants = false
	
	private var statusText: LocalizedStringResource {
		"^[\(plantsNeedingWater + plantsNeedingRotation + plantsNeedFertilizing) task](inflect: true) toward happy plants"
	}
	  
	var body: some View {
		@Bindable var settings = settings
		NavigationStack {
			ZStack {
				// Background Material
				MaterialBackground()
				  
				// Plant List
				ScrollView {
					WeatherOverview()
					
					// Today's Tasks Header
					HStack {
						VStack(alignment: .leading, spacing: 4) {
							Text("Today")
								.font(.title2)
								.fontWeight(.bold)
							Text(statusText)
								.font(.subheadline)
								.foregroundStyle(.secondary)
						}
						
						Spacer()
						
						Button(action: startWateringSession) {
							Label("Start", systemImage: "play.fill")
						}
						.buttonStyle(.borderedProminent)
						.disabled(plantsNeedingCare == 0)
					}
					
					let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: horizontalSizeClass == .regular ? 3 : 2)
					
					LazyVGrid(columns: columns, spacing: 16) {
						ForEach(sortedPlants) { plant in
							PlantCardView(plant: plant)
						}
					}
					.padding(.top)
				}
				.padding(.horizontal)
				.scrollIndicators(.hidden)
			}
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(action: addPlant) {
						Image(systemName: "plus")
					}
				}
				
				ToolbarItem(placement: .navigationBarLeading) {
					Button(action: settings.showSettings) {
						Image(systemName: "gear")
					}
				}
			}
		}
		.sheet(isPresented: $isCaringForPlants) {
			CareSessionView(plants: Array(sortedPlants))
		}
		.sheet(isPresented: $settings.isShowingSettings) {
			SettingsView()
		}
		.sheet(isPresented: $isAddingPlant) {
			PlantFormView(mode: .add, viewModel: PlantFormViewModel())
		}
		.alert("iCloud Sync Error", 
			   isPresented: .init(
				get: { imageManager.cloudError != nil },
				set: { if !$0 { imageManager.cloudError = nil } }
			   )) {
			Button("OK") {
				imageManager.cloudError = nil
			}
		} message: {
			Text(imageManager.cloudError ?? "")
		}
	}
	  
	// Computed property to count plants needing water
	private var plantsNeedingWater: Int {
		sortedPlants.filter { $0.needsWatering }.count
	}
	  
	// Computed property to count plants needing rotation
	private var plantsNeedingRotation: Int {
		sortedPlants.filter { $0.needsRotation }.count
	}
	  
	// Computed property to count plants needing care
	private var plantsNeedingCare: Int {
		sortedPlants.filter { $0.needsWatering || $0.needsRotation || $0.needsFertilizing }.count
	}
	
	private var plantsNeedFertilizing: Int {
		sortedPlants.filter(\.needsFertilizing).count
	}
	  
	// Function to start watering session
	private func startWateringSession() {
		isCaringForPlants = true
	}
	  
	// Function to add a new plant
	func addPlant() {
		isAddingPlant = true
	}
	  
	private func dismissCareSession() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			isCaringForPlants = false
		}
	}
}
  
struct MaterialBackground: View {
	var body: some View {
		// Using the built-in material for background
		Rectangle()
			.foregroundStyle(.regularMaterial)
			.ignoresSafeArea()
	}
}
  
//#if DEBUG
//#Preview {
//	return ContentView()
//		.environment(WeatherManager(previewWeather: .init(
//			temperature: 72,
//			conditionDescription: "Sunny",
//			symbolName: "sun.max.fill",
//			timestamp: Date(),
//			wind: WeatherData.Wind(speed: 20, direction: .north)
//		)))
//		.environment(SettingsCoordinator())
//		.modelContainer(Plant.previewContainer)
//}
//#endif
