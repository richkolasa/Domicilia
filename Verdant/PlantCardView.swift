//
//  PlantCardView.swift
//  Verdant
//
//  Created by Richard Kolasa on 11/30/24.
//

import SwiftUI

struct CareProgressIcon: View {
	let systemName: String
	let foregroundColor: Color
	let nextDate: Date
	let schedule: Schedule
	
	var progress: Double {
		let calendar = Calendar.current
		let now = Date()
		
		// If the next date is today or has passed, show complete circle
		if calendar.startOfDay(for: now) >= calendar.startOfDay(for: nextDate) {
			return 1.0
		}
		
		// Get the start date (last care date)
		let startDate = calendar.date(byAdding: .day, value: -schedule.dayCount, to: nextDate) ?? now
		
		// Calculate total duration and time elapsed
		let totalDuration = nextDate.timeIntervalSince(startDate)
		let elapsed = now.timeIntervalSince(startDate)
		
		// Return progress from 0 to 1, capped at bounds
		return min(1, max(0, elapsed / totalDuration))
	}
	
	var body: some View {
		ZStack {
			// Progress circle
			Circle()
				.stroke(.ultraThinMaterial, lineWidth: 3)
			
			Circle()
				.trim(from: 0, to: progress)
				.stroke(foregroundColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
				.rotationEffect(.degrees(-90))
			
			
		}
		.frame(width: 34, height: 34)
		.background(.thinMaterial, in: Circle())
		.shadow(color: .black.opacity(0.15), radius: 3, y: 1)
	}
}

// Add to Schedule enum:
extension Schedule {
	var dayCount: Int {
		switch self {
		case .none: return 0
		case .daily: return 1
		case .weekly: return 7
		case .biweekly: return 14
		case .monthly: return 30
		}
	}
}

struct PlantCardView: View {
	@Environment(PlantImageManager.self) private var imageManager
	let plant: Plant
	private let cornerRadius: CGFloat = 16
	@Namespace private var namespace

	var body: some View {
		NavigationLink {
			PlantDetailView(plant: plant)
				.navigationTransition(.zoom(sourceID: "zoom", in: namespace))
		} label: {
			VStack(spacing: 0) {
				// Image at the top with status overlays
				ZStack(alignment: .topTrailing) {
					ZStack(alignment: .bottom) {
						if let image = imageManager.loadImage(for: plant) {
							Image(uiImage: image)
								.resizable()
								.scaledToFit()
								.clipped()
						}
					}
					  
					// Status icons
					VStack(spacing: 6) {
						if plant.needsWatering {
							// Icon
							Image(systemName: "drop.fill")
								.resizable()
								.scaledToFit()
								.frame(width: 18, height: 18)
								.foregroundStyle(.primary)
								.frame(width: 34, height: 34)
								.background(.thinMaterial, in: Circle())
								.shadow(color: .black.opacity(0.15), radius: 3, y: 1)
						}
						if plant.needsRotation {
							Image(systemName: "arrow.triangle.2.circlepath")
								.resizable()
								.scaledToFit()
								.frame(width: 18, height: 18)
								.foregroundStyle(.primary)
								.frame(width: 34, height: 34)
								.background(.thinMaterial, in: Circle())
								.shadow(color: .black.opacity(0.15), radius: 3, y: 1)
						}
						
						if plant.needsFertilizing {
							Image(systemName: "leaf.fill")
								.resizable()
								.scaledToFit()
								.frame(width: 18, height: 18)
								.foregroundStyle(.primary)
								.frame(width: 34, height: 34)
								.background(.thinMaterial, in: Circle())
								.shadow(color: .black.opacity(0.15), radius: 3, y: 1)
						}
					}
					.padding(8)
				}
			}
			.background(.ultraThinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
			.matchedTransitionSource(id: "zoom", in: namespace)
		}
		.buttonStyle(.plain)
	}
}
