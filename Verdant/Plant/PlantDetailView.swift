import SwiftUI
import Foundation

struct PlantDetailView: View {
    @Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext
    let plant: Plant
    @State private var showingEditSheet = false
    
    private func formatNextCareDate(_ date: Date, lastDate: Date?) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextDate = calendar.startOfDay(for: date)
        
		if calendar.isDateInToday(nextDate) {
			return "Needs care today"
		}
		
		if calendar.isDateInTomorrow(nextDate) {
			return "Needs care tomorrow"
		}
		
		let daysUntil = calendar.dateComponents([.day], from: today, to: nextDate).day ?? 0
		if daysUntil <= 7 {
			let weekday = calendar.component(.weekday, from: nextDate)
			let weekdaySymbols = calendar.weekdaySymbols
			return "Coming up \(weekdaySymbols[weekday - 1])"
		} else {
			let formatter = DateFormatter()
			formatter.dateStyle = .medium
			return "Planned for \(formatter.string(from: date))"
		}
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Image
//                if let imageData = plant.imageData,
//                   let uiImage = UIImage(data: imageData) {
//                    Image(uiImage: uiImage)
//                        .resizable()
//                        .scaledToFit()
//						.frame(maxWidth: 300)
//                        .clipShape(RoundedRectangle(cornerRadius: 16))
//                        .padding(.horizontal, 32)
//                }
                
                // Info Sections
                VStack(spacing: 32) {
                    // Care Schedule Card
                    InfoCard(title: "Care Schedule") {
                        VStack(spacing: 16) {
                            // Watering Schedule
                            HStack {
                                Label {
									Text("Water \(plant.wateringSchedule.rawValue)")
                                } icon: {
                                    Image(systemName: "drop.fill")
                                        .foregroundStyle(.blue)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
									Text(formatNextCareDate(plant.nextWateringDate, lastDate: plant.lastWateredDate))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            
                            
                            // Rotation Schedule
							if plant.rotationSchedule != .none {
								Divider()
								HStack {
									Label {
										Text("Rotate \(plant.rotationSchedule.rawValue)")
									} icon: {
										Image(systemName: "arrow.triangle.2.circlepath")
											.foregroundStyle(.green)
									}
									
									Spacer()
									
									if let nextRotation = plant.nextRotationDate {
										VStack(alignment: .trailing) {
											Text(formatNextCareDate(
												nextRotation,
												lastDate: plant.lastRotatedDate
											))
											.font(.caption)
											.foregroundStyle(.secondary)
										}
									} else {
										Text("—")
											.font(.caption)
											.foregroundStyle(.secondary)
									}
								}
							}
							
							if plant.fertilizationSchedule != .none {
								Divider()
								HStack {
									Label {
										Text("Fertilize \(plant.rotationSchedule.rawValue)")
									} icon: {
										Image(systemName: "leaf.fill")
											.foregroundStyle(.blue)
									}
									
									Spacer()
									
									if let nextFert = plant.nextFertilizationDate {
										VStack(alignment: .trailing) {
											Text(formatNextCareDate(
												nextFert,
												lastDate: plant.lastFertilizedDate
											))
											.font(.caption)
											.foregroundStyle(.secondary)
										}
									} else {
										Text("—")
											.font(.caption)
											.foregroundStyle(.secondary)
									}
								}
							}
                        }
                    }
                    
                    // Notes Card if exists
                    InfoCard(title: "Notes") {
                        if let notes = plant.notes, !notes.isEmpty {
                            Text(notes)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("Add notes about your plant's care preferences, location details, or other reminders")
                                .foregroundStyle(.secondary.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .italic()
                        }
                    }
					
					Button(role: .destructive) {
						modelContext.delete(plant)
						dismiss()
					} label: {
						Label("Delete", systemImage: "trash.fill")
					}

                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(plant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
			PlantFormView(mode: .edit, viewModel: PlantFormViewModel(plant: plant))
        }
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
			SectionHeader(title: title)
            
            content()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
} 
