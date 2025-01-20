import Observation
import CoreLocation
import Foundation
@preconcurrency import WeatherKit
import SwiftUI
import Combine

@Observable
class WeatherManager: NSObject, CLLocationManagerDelegate {
	var weatherError: String?
	var currentWeather: WeatherData?
	var plantAdvice = ""
	private let locationManager: CLLocationManager
	private let weatherService: WeatherService
	private let minimumFetchInterval: TimeInterval
	private let defaults: UserDefaults
	private let weatherCacheKey: String
	private let locationCacheKey = "last_known_location"
	private var currentLocation: CLLocation? {
		didSet {
			if let location = currentLocation {
				defaults.set(["latitude": location.coordinate.latitude,
							"longitude": location.coordinate.longitude], forKey: locationCacheKey)
			}
		}
	}
	private var cancellables: [AnyCancellable] = []
	
	init(
		locationManager: CLLocationManager = .init(),
		weatherService: WeatherService = .shared,
		minimumFetchInterval: TimeInterval = 1800,
		defaults: UserDefaults = .standard,
		weatherCacheKey: String = "cached_weather",
		previewWeather: WeatherData? = nil
	) {
		self.locationManager = locationManager
		self.weatherService = weatherService
		self.minimumFetchInterval = minimumFetchInterval
		self.defaults = defaults
		self.weatherCacheKey = weatherCacheKey
		self.currentWeather = previewWeather
		
		super.init()
		
		// Load last known location if available
		if let locationDict = defaults.dictionary(forKey: locationCacheKey) as? [String: Double],
		   let latitude = locationDict["latitude"],
		   let longitude = locationDict["longitude"] {
			self.currentLocation = CLLocation(latitude: latitude, longitude: longitude)
		}
		
		self.locationManager.delegate = self
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
		self.startLocationUpdates()
		
		defaults.publisher(for: \.useCelsius)
			.sink { [weak self] useCelsius in
				self?.currentWeather?.useCelsius = useCelsius
			}
			.store(in: &cancellables)
		
		defaults.publisher(for: \.useKph)
			.sink { [weak self] useKph in
				self?.currentWeather?.useKph = useKph
			}
			.store(in: &cancellables)
	}
	
	private func startLocationUpdates() {
		locationManager.requestWhenInUseAuthorization()
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		let status = manager.authorizationStatus
		
		switch status {
		case .authorizedWhenInUse, .authorizedAlways:
			manager.startUpdatingLocation()
		case .denied, .restricted:
			weatherError = "Location permissions are denied. Enable them in Settings."
		case .notDetermined:
			manager.requestWhenInUseAuthorization()
		@unknown default:
			weatherError = "An unknown location authorization state occurred."
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.last else { return }
		
		let forceUpdate: Bool
		if let currentLocation = currentLocation {
			// Force update if distance is more than 100 meters
			forceUpdate = location.distance(from: currentLocation) > 100
		} else {
			forceUpdate = true
		}
		
		fetchWeather(for: location, forceUpdate: forceUpdate)
		currentLocation = location
		locationManager.stopUpdatingLocation()
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		weatherError = "Failed to get location. Please try again."
	}
	
	private func fetchWeather(for location: CLLocation, forceUpdate: Bool = false) {
		guard forceUpdate || !loadCachedWeather() else {
			return
		}
		
		Task {
			do {
				let currentWeather = try await weatherService.weather(
					for: location,
					including: .current
				)
				
				weatherError = nil
				
				DispatchQueue.main.async {
					let useCelsius = self.defaults.bool(forKey: "useCelsius")
					let useKph = self.defaults.bool(forKey: "useKph")
					
					let weatherData = WeatherData(
						temperatureMeasurement: currentWeather.temperature,
						conditionDescription: currentWeather.condition.description,
						symbolName: currentWeather.symbolName,
						timestamp: Date(),
						wind: WeatherData.Wind(
							speed: currentWeather.wind.speed.converted(to: .milesPerHour).value,
							direction: currentWeather.wind.compassDirection.toWeatherData
						),
						useCelsius: useCelsius,
						useKph: useKph
					)
					withAnimation {
						self.currentWeather = weatherData
						self.plantAdvice = self.generatePlantAdvice(for: weatherData)
					}
					self.cacheWeather(weatherData)
				}
			} catch {
				weatherError = "Error fetching weather. Please try again."
			}
		}
	}
	
	private func loadCachedWeather() -> Bool {
		guard let data = defaults.data(forKey: weatherCacheKey),
			  let cached = try? JSONDecoder().decode(WeatherData.self, from: data), cached.timestamp.addingTimeInterval(minimumFetchInterval) > Date() else {
			return false
		}
		
		self.currentWeather = cached
		self.plantAdvice = generatePlantAdvice(for: self.currentWeather!)
		return true
	}
	
	private func cacheWeather(_ weather: WeatherData) {
		guard let encoded = try? JSONEncoder().encode(weather) else {
			return
		}
		defaults.set(encoded, forKey: weatherCacheKey)
	}
	
	private func generatePlantAdvice(for weather: WeatherData) -> String {
		// Plant advice logic (unchanged)
		return "Current conditions are good for your plants."
	}
}

extension UserDefaults {
	@objc dynamic var useCelsius: Bool {
		return bool(forKey: "useCelsius")
	}
	
	@objc dynamic var useKph: Bool {
		return bool(forKey: "useKph")
	}
}
