import SwiftUI
import Observation
import SwiftData

struct PlantFormView: View {
	@Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
	@Environment(PlantManager.self) private var plantManager
    @State private var name = ""
    @State private var notes = ""
    @State private var wateringSchedule = Schedule.weekly
    @State private var rotationSchedule = Schedule.none
    @State private var fertilizerSchedule = Schedule.none
    @State private var hasImage = false
    @State private var image: UIImage?
	
    // If editing existing plant
    var plant: Plant?
    let mode: FormMode
    
    enum FormMode {
        case add
        case edit
        
        var title: String {
            switch self {
            case .add: return "Add Plant"
            case .edit: return "Edit Plant"
            }
        }
    }
    
    init(mode: FormMode, plant: Plant? = nil) {
        self.mode = mode
        self.plant = plant
        // Use _name to set initial state
        _name = State(initialValue: plant?.name ?? "")
        _notes = State(initialValue: plant?.notes ?? "")
        _wateringSchedule = State(initialValue: plant?.wateringSchedule ?? .weekly)
        _rotationSchedule = State(initialValue: plant?.rotationSchedule ?? .none)
        _fertilizerSchedule = State(initialValue: plant?.fertilizationSchedule ?? .none)
        _hasImage = State(initialValue: plant?.imageFileName != nil)
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasImage
    }
    
    private func updatePlant() async throws {
        if let plant = plant {
            // Update existing plant
            plant.name = name
            plant.notes = notes.isEmpty ? nil : notes
            
            if plant.wateringSchedule != wateringSchedule {
                plant.wateringSchedule = wateringSchedule
                if let date = wateringSchedule.nextDate() {
                    plant.nextWateringDate = date
                }
            }
            
            if plant.rotationSchedule != rotationSchedule {
                plant.rotationSchedule = rotationSchedule
                if let date = rotationSchedule.nextDate() {
                    plant.nextRotationDate = date
                }
            }
            
            if plant.fertilizationSchedule != fertilizerSchedule {
                plant.fertilizationSchedule = fertilizerSchedule
                if let date = fertilizerSchedule.nextDate() {
                    plant.nextFertilizationDate = date
                }
            }
            
            try await plantManager.updatePlant(plant, image: image)
        } else {
            // Create new plant
            let now = Date()
            let newPlant = Plant(
                name: name,
                wateringSchedule: wateringSchedule,
                lastWateredDate: now,
                nextWateringDate: wateringSchedule.nextDate() ?? now,
                rotationSchedule: rotationSchedule,
                lastRotatedDate: rotationSchedule != .none ? now : nil,
                nextRotationDate: rotationSchedule.nextDate(),
                fertilizationSchedule: fertilizerSchedule,
                lastFertilizedDate: fertilizerSchedule != .none ? now : nil,
                nextFertilizationDate: fertilizerSchedule.nextDate(),
                notes: notes
            )
            
            try await plantManager.addPlant(newPlant, image: image)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Photo Button
					CameraImageButton(image: $image)
						.padding(.top, 16)
                    
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            title: "Basic Info"
                        )
                        
                        VStack {
                            TextField("Name", text: $name)
                                .textFieldStyle(.plain)
                                .padding()
                        }
						.background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Care Schedule Section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            title: "Care Schedule",
                            subtitle: "Set up your plant's care routines"
                        )
                        
                        VStack(spacing: 1) {
                            CareOptionRow(
                                icon: "drop.fill",
                                iconColor: .blue,
                                title: "Watering",
                                schedule: $wateringSchedule,
                                options: [.daily, .weekly, .biweekly, .monthly]
                            )
                            
                            Divider()
                                .padding(.horizontal)
                            
                            CareOptionRow(
                                icon: "arrow.triangle.2.circlepath",
                                iconColor: .green,
                                title: "Rotation",
                                schedule: $rotationSchedule,
                                options: [.none, .weekly, .biweekly, .monthly]
                            )
                            
                            Divider()
                                .padding(.horizontal)
                            
                            CareOptionRow(
                                icon: "leaf.fill",
                                iconColor: .indigo,
                                title: "Fertilizer",
                                schedule: $fertilizerSchedule,
                                options: [.none, .weekly, .biweekly, .monthly]
                            )
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            title: "Notes",
                            subtitle: "Add any care instructions or reminders"
                        )
                        
                        TextField("Care notes", text: $notes, axis: .vertical)
                            .textFieldStyle(.plain)
                            .frame(minHeight: 100, alignment: .top)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(mode.title)
                        .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
					if plantManager.isSaving {
						ProgressView()
					} else {
						Button("Save") {
							Task {
								try await updatePlant()
								dismiss()
							}
						}
						.disabled(!isValid)
					}
                }
            }
            .task {
                if mode == .edit, let plant = plant {
                    image = plantManager.loadImage(for: plant)
                }
            }
			.onChange(of: image) { _, newValue in
				hasImage = newValue != nil
			}
			.interactiveDismissDisabled(plantManager.isSaving)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
	init(title: String, subtitle: String? = nil) {
		self.title = title
		self.subtitle = subtitle
	}
	
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
			if let subtitle {
				Text(subtitle)
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
        }
    }
}

struct CareOptionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var schedule: Schedule
    let options: [Schedule]
    
    var body: some View {
        Menu {
            Picker(title, selection: $schedule) {
                ForEach(options, id: \.self) { option in
					Text(option.rawValue)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
                
                Text(title)
                
                Spacer()
                
				Text(schedule.rawValue)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

#Preview("Add Plant") {
    PlantFormView(mode: .add)
        .previewWith()
}

#Preview("Edit Plant") {
    PlantFormView(mode: .edit, plant: try! PreviewContainer.shared.modelContext.fetch(FetchDescriptor<Plant>()).first!)
        .previewWith()
}
