import SwiftUI
import SwiftData

struct CareSessionView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(PlantManager.self) var plantManager
	@State private var currentIndex = 0
	@State private var showingCelebration = false
	@State private var completedTasks: Set<CareTask> = []
	
	@Query var plants: [Plant]
	
	var currentPlant: Plant {
		plants[currentIndex]
	}
	
	var allTasks: [CareTask] {
		var tasks: [CareTask] = []
		for plant in plants {
			if plant.needsWatering {
				tasks.append(CareTask(type: .watering, plantName: plant.name))
			}
			if plant.needsRotation {
				tasks.append(CareTask(type: .rotation, plantName: plant.name))
			}
			if plant.needsFertilizing {
				tasks.append(CareTask(type: .fertilizing, plantName: plant.name))
			}
		}
		return tasks
	}
	
	var isComplete: Bool {
		let wateringComplete = !currentPlant.needsWatering || completedTasks.contains(CareTask(type: .watering, plantName: currentPlant.name))
		let rotationComplete = !currentPlant.needsRotation || completedTasks.contains(CareTask(type: .rotation, plantName: currentPlant.name))
		let fertilizingComplete = !currentPlant.needsFertilizing || completedTasks.contains(CareTask(type: .fertilizing, plantName: currentPlant.name))
		
		return wateringComplete && rotationComplete && fertilizingComplete
	}
	
	func completeTask(_ task: CareTask) {
		let now = Date()
		
		switch task.type {
		case .watering:
			currentPlant.lastWateredDate = now
			if let nextDate = currentPlant.wateringSchedule.nextDate() {
				currentPlant.nextWateringDate = nextDate
			}
			
		case .rotation:
			currentPlant.lastRotatedDate = now
			if let nextDate = currentPlant.rotationSchedule.nextDate() {
				currentPlant.nextRotationDate = nextDate
			}
			
		case .fertilizing:
			currentPlant.lastFertilizedDate = now
			if let nextDate = currentPlant.fertilizationSchedule.nextDate() {
				currentPlant.nextFertilizationDate = nextDate
			}
		}
		
		completedTasks.insert(task)

		// Only start advancing if all tasks are complete and we're not already advancing
		if isComplete && hasNextPlant {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
				withAnimation {
					self.advanceToNextPlant()
				}
			}
		}
	}
	
	var hasNextPlant: Bool {
		currentIndex < plants.count - 1
	}
	
	func advanceToNextPlant() {
		guard hasNextPlant else { return }
		currentIndex += 1
	}
	
	var body: some View {
		NavigationStack {
			if !hasNextPlant && isComplete {
				CelebrationView {
					dismiss()
				}
				.transition(.opacity)
			} else {
				VStack(spacing: 24) {
					// Current Plant Info
					VStack(spacing: 16) {
						if let image = plantManager.loadImage(for: currentPlant) {
							Image(uiImage: image)
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 200)
								.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
						}
						Text(currentPlant.name)
					}
					.padding(.top)
								
					// Task Checklist
					VStack(alignment: .leading, spacing: 12) {
						Text("Tasks")
							.font(.headline)
							.padding(.horizontal)
							.frame(maxWidth: .infinity, alignment: .leading)
						
						VStack(spacing: 1) {
							let lastWaterDate = currentPlant.lastFertilizedDate ?? Date.distantFuture
							let wasWateredToday = Calendar.current.isDateInToday(lastWaterDate)
							if currentPlant.needsWatering || wasWateredToday {
								TaskButton(
									task: CareTask(
										type: .watering,
										plantName: currentPlant.name
									),
									isComplete: completedTasks.contains(
										CareTask(
											type: .watering,
											plantName: currentPlant.name
										)
									),
									action: { completeTask(
										CareTask(
											type: .watering,
											plantName: currentPlant.name
										)
									)
									}
								)
							}
							
							let lastRotated = currentPlant.lastRotatedDate ?? Date.distantFuture
							let wasRotatedToday = Calendar.current.isDateInToday(lastRotated)
							if currentPlant.needsRotation || wasRotatedToday {
								TaskButton(
									task: CareTask(
										type: .rotation,
										plantName: currentPlant.name
									),
									isComplete: completedTasks.contains(
										CareTask(
											type: .rotation,
											plantName: currentPlant.name
										)
									),
									action: { completeTask(
										CareTask(
											type: .rotation,
											plantName: currentPlant.name
										)
									)
									}
								)
							}
							
							let lastFertilized = currentPlant.lastFertilizedDate ?? Date.distantFuture
							let wasFertlizedToday = Calendar.current.isDateInToday(lastFertilized)
							if currentPlant.needsFertilizing || wasFertlizedToday {
								TaskButton(
									task: CareTask(
										type: .fertilizing,
										plantName: currentPlant.name
									),
									isComplete: completedTasks.contains(
										CareTask(
											type: .fertilizing,
											plantName: currentPlant.name
										)
									),
									action: { completeTask(
										CareTask(
											type: .fertilizing,
											plantName: currentPlant.name
										)
									)
									}
								)
							}
						}
						.clipShape(RoundedRectangle(cornerRadius: 12))
					}
					.padding(.horizontal)
					
					Spacer()
				}
				.padding(.top, 24)
			}
		}
	}
}

struct TaskButton: View {
	let task: CareTask
	let isComplete: Bool
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			HStack {
				Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
					.foregroundStyle(isComplete ? .secondary : .primary)
				
				Text(task.description)
					.strikethrough(isComplete)
					.foregroundStyle(isComplete ? .secondary : .primary)
				
				Spacer()
			}
			.padding()
			.background(.ultraThinMaterial)
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	CareSessionView()
		.previewWith()
}
