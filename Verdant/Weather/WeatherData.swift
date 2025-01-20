//
//  WeatherData.swift
//  Verdant
//
//  Created by Richard Kolasa on 11/30/24.
//

import Foundation
import WeatherKit

struct WeatherData: Codable, Equatable {
	var temperatureMeasurement: Measurement<UnitTemperature>
	var conditionDescription: String
	var symbolName: String
	var timestamp: Date
	let wind: Wind
	var useCelsius: Bool
	var useKph: Bool
	
	init(
		temperatureMeasurement: Measurement<UnitTemperature>,
		conditionDescription: String,
		symbolName: String,
		timestamp: Date = Date(),
		wind: WeatherData.Wind,
		useCelsius: Bool = false,
		useKph: Bool = false
	) {
		self.temperatureMeasurement = temperatureMeasurement
		self.conditionDescription = conditionDescription
		self.symbolName = symbolName
		self.timestamp = timestamp
		self.wind = wind
		self.useCelsius = useCelsius
		self.useKph = useKph
	}
	
	var temperature: Int {
		Int(useCelsius ? temperatureMeasurement.value : temperatureMeasurement.converted(to: .fahrenheit).value)
	}
	
	struct Wind: Codable, Equatable {
		let speed: Double      // stored in mph, convert for display if needed
		let direction: CompassDirection
		
		enum CompassDirection: String, Codable {
			case north = "N"
			case northNortheast = "NNE"
			case northeast = "NE"
			case eastNortheast = "ENE"
			case east = "E"
			case eastSoutheast = "ESE"
			case southeast = "SE"
			case southSoutheast = "SSE"
			case south = "S"
			case southSouthwest = "SSW"
			case southwest = "SW"
			case westSouthwest = "WSW"
			case west = "W"
			case westNorthwest = "WNW"
			case northwest = "NW"
			case northNorthwest = "NNW"
			
			var symbol: String {
				switch self {
				case .north: return "arrow.down"
				case .northNortheast, .northeast, .eastNortheast: return "arrow.down.left"
				case .east: return "arrow.left"
				case .eastSoutheast, .southeast, .southSoutheast: return "arrow.up.left"
				case .south: return "arrow.up"
				case .southSouthwest, .southwest, .westSouthwest: return "arrow.up.right"
				case .west: return "arrow.right"
				case .westNorthwest, .northwest, .northNorthwest: return "arrow.down.right"
				}
			}
		}
	}
	
	var temperatureString: String {
		"\(temperature)°"
	}
	
	var speedString: String {
		let speedValue = useKph ? wind.speed * 1.60934 : wind.speed // Convert mph to kph if needed
		return "\(Int(speedValue)) \(useKph ? "km/h" : "mph")"
	}
}

extension WeatherKit.Wind.CompassDirection {
	var toWeatherData: WeatherData.Wind.CompassDirection {
		switch self {
		case .north: return .north
		case .northNortheast: return .northNortheast
		case .northeast: return .northeast
		case .eastNortheast: return .eastNortheast
		case .east: return .east
		case .eastSoutheast: return .eastSoutheast
		case .southeast: return .southeast
		case .southSoutheast: return .southSoutheast
		case .south: return .south
		case .southSouthwest: return .southSouthwest
		case .southwest: return .southwest
		case .westSouthwest: return .westSouthwest
		case .west: return .west
		case .westNorthwest: return .westNorthwest
		case .northwest: return .northwest
		case .northNorthwest: return .northNorthwest
		@unknown default: return .north
		}
	}
}
