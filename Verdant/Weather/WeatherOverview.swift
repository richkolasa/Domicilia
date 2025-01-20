//
//  P.swift
//  Verdant
//
//  Created by Richard Kolasa on 11/30/24.
//

import SwiftUI

struct WeatherOverview: View {
	@Environment(WeatherManager.self) var weatherManager
	
	var body: some View {
		if let weather = weatherManager.currentWeather {
			HStack(spacing: 16) {
				Image(systemName: weather.symbolName)
					.font(.system(size: 55))
					.foregroundStyle(.primary)
					.background(.thinMaterial)
				
				VStack(alignment: .leading, spacing: 4) {
					HStack(spacing: 4) {
						Text(weather.temperatureString)
							.font(.largeTitle)
							.fontWeight(.semibold)
						
						VStack(alignment: .leading) {
							Text(weather.conditionDescription)
								.font(.headline)
								.foregroundStyle(.secondary)
							
							if weather.wind.speed > 5 {
								HStack(spacing: 4) {
									Image(systemName: weather.wind.direction.symbol)
									Text(weather.speedString)
								}
								.font(.subheadline)
								.foregroundStyle(.secondary)
							}
						}
					}
					Text(weatherManager.plantAdvice)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(16)
			.background(.ultraThinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 16))
			.padding(.vertical)
		}
	}
}
