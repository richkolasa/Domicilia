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
	
	func startLocationUpdates() {
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
		let tempF = weather.temperatureMeasurement.converted(to: .fahrenheit).value
		
		let coldAdvice = [
			"Brr! Keep those plant babies away from drafty windows and cold glass today!",
			"Time to protect your green friends from the cold - move them away from chilly windows!",
			"Your plants would appreciate a cozy spot away from any cold drafts today.",
			"Chilly day! Make sure your plants aren't touching any cold windows.",
			"Extra care needed today - keep your leafy pals away from cold spots!",
			"Your plants are saying 'baby, it's cold outside!' Keep them snug and draft-free.",
			"Cold snap alert! Time to create a warm sanctuary for your indoor garden.",
			"Protect your green team from the chill - watch out for those cold windowsills!",
			"Today's a good day to check for cold spots near your plant locations.",
			"Brrr! Help your plants stay cozy by keeping them away from cold windows."
		]
		
		let coolAdvice = [
			"Cool temps mean slower growth - time to ease up on the watering!",
			"Your plants are taking it easy in these cool temps - water less frequently.",
			"Perfect weather for a plant siesta - they'll need less water than usual.",
			"Growth is slowing down with these cool temps - adjust watering accordingly!",
			"Your plants are in energy-saving mode - go easy on the water today.",
			"Cool and calm! Your plants need less water in these temperatures.",
			"Time to dial back the watering routine - plants are chilling today!",
			"Your green friends are moving at a slower pace in this cool weather.",
			"Remember: cool temps mean your plants are less thirsty than usual!",
			"Easy does it with watering - your plants are in slow-growth mode today."
		]
		
		let idealAdvice = [
			"Perfect conditions for your plant family today!",
			"Your plants are living their best life in these ideal temperatures!",
			"Goldilocks weather - just right for your green friends!",
			"Your plants are loving these perfect conditions!",
			"Ideal growing weather - your plants couldn't be happier!",
			"These temperatures are a plant paradise!",
			"Your indoor garden is thriving in these perfect conditions!",
			"Temperature sweet spot - your plants are in their happy place!",
			"Wonderful growing conditions for your green companions today!",
			"Your plants are sending good vibes in these ideal temperatures!"
		]
		
		let warmAdvice = [
			"Warm day! Keep an eye on soil moisture - your plants might be extra thirsty.",
			"Time to monitor those moisture levels - plants are drinking up in this warmth!",
			"Your plants might need an extra drink in today's warm weather.",
			"Watch those soil moisture levels - it's getting warm out there!",
			"Thirsty weather ahead - check your plants' water needs more often.",
			"Your green friends might need extra hydration in this warmth!",
			"Keep those moisture meters handy - warm weather means thirsty plants!",
			"Don't forget to check on your plants' water needs in this warm weather.",
			"Warm and wonderful - just remember to monitor soil moisture!",
			"Your plants might appreciate extra water checks today!"
		]
		
		let hotAdvice = [
			"Hot day! Consider misting your tropical plants and keeping them from direct sun.",
			"Time for some plant pampering - mist those tropicals and watch for sun exposure!",
			"Help your plants beat the heat - extra misting and shade might be needed.",
			"Your tropical plants would love some misting in this heat!",
			"Keep those plant babies cool - mist and shade are your friends today.",
			"Heat alert! Show your plants some love with misting and sun protection.",
			"Your plants might appreciate a tropical spa day with misting!",
			"Time to create a cool oasis for your green friends - mist and shade recommended.",
			"Help your plants stay fresh - consider misting and reducing sun exposure.",
			"Hot weather calls for extra plant care - misting and shade can help!"
		]
		
		let advice: [String]
		switch tempF {
		case ...45:
			advice = coldAdvice
		case 46...55:
			advice = coolAdvice
		case 56...75:
			advice = idealAdvice
		case 76...85:
			advice = warmAdvice
		default: // 86+
			advice = hotAdvice
		}
		
		return advice.randomElement() ?? advice[0]
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
