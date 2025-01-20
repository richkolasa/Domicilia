import SwiftUI

struct CareSessionView: View {
	@Environment(\.dismiss) private var dismiss
	@State private var viewModel: CareSessionViewModel
	@State private var showingCelebration = false
	
	init(plants: [Plant]) {
		_viewModel = State(wrappedValue: CareSessionViewModel(plants: plants))
	}
	
	var body: some View {
		NavigationStack {
			if !viewModel.hasNextPlant && viewModel.isComplete {
				CelebrationView {
					dismiss()
				}
				.transition(.opacity)
			} else {
				VStack(spacing: 24) {
					// Current Plant Info
					VStack(spacing: 16) {
//						if let imageData = viewModel.currentPlant.imageData,
//						   let uiImage = UIImage(data: imageData) {
//							Image(uiImage: uiImage)
//								.resizable()
//								.aspectRatio(contentMode: .fit)
//								.frame(width: 200)
//								.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
//						}
//						
						Text(viewModel.currentPlant.name)
					}
					.padding(.top)
								
					// Task Checklist
					VStack(alignment: .leading, spacing: 12) {
						Text("Tasks")
							.font(.headline)
							.padding(.horizontal)
							.frame(maxWidth: .infinity, alignment: .leading)
						
						VStack(spacing: 1) {
							let lastWaterDate = viewModel.currentPlant.lastFertilizedDate ?? Date.distantFuture
							let wasWateredToday = Calendar.current.isDateInToday(lastWaterDate)
							if viewModel.currentPlant.needsWatering || wasWateredToday {
								TaskButton(
									task: CareTask(type: .watering, plantName: viewModel.currentPlant.name),
									isComplete: viewModel.completedTasks.contains(CareTask(type: .watering, plantName: viewModel.currentPlant.name)),
									action: { viewModel.completeTask(CareTask(type: .watering, plantName: viewModel.currentPlant.name)) }
								)
							}
							
							let lastRotated = viewModel.currentPlant.lastRotatedDate ?? Date.distantFuture
							let wasRotatedToday = Calendar.current.isDateInToday(lastRotated)
							if viewModel.currentPlant.needsRotation || wasRotatedToday {
								TaskButton(
									task: CareTask(type: .rotation, plantName: viewModel.currentPlant.name),
									isComplete: viewModel.completedTasks.contains(CareTask(type: .rotation, plantName: viewModel.currentPlant.name)),
									action: { viewModel.completeTask(CareTask(type: .rotation, plantName: viewModel.currentPlant.name)) }
								)
							}
							
							let lastFertilized = viewModel.currentPlant.lastFertilizedDate ?? Date.distantFuture
							let wasFertlizedToday = Calendar.current.isDateInToday(lastFertilized)
							if viewModel.currentPlant.needsFertilizing || wasFertlizedToday {
								TaskButton(
									task: CareTask(type: .fertilizing, plantName: viewModel.currentPlant.name),
									isComplete: viewModel.completedTasks.contains(CareTask(type: .fertilizing, plantName: viewModel.currentPlant.name)),
									action: { viewModel.completeTask(CareTask(type: .fertilizing, plantName: viewModel.currentPlant.name)) }
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
