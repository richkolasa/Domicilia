import SwiftUI
import Observation

struct PlantFormView: View {
	@Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(PlantImageManager.self) private var imageManager
    @State private var viewModel: PlantFormViewModel
    @State private var showingCamera = false
    @State private var image: UIImage?
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
        
        var saveButtonText: String {
            switch self {
            case .add: return "Add"
            case .edit: return "Save"
            }
        }
    }
    
	init(mode: FormMode, viewModel: PlantFormViewModel) {
        self.mode = mode
        
//        if let plant {
//			viewModel = PlantFormViewModel(context: modelContext, plant: plant)
//            if let imageData = plant.imageData {
//                _image = State(wrappedValue: UIImage(data: imageData))
//            }
//        } else {
//			viewModel = PlantFormViewModel(context: modelContext)
//        }
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Photo Button
                    Button {
                        showingCamera = true
                    } label: {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(.quaternary, lineWidth: 1)
                                }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(.quaternary)
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                            }
                        }
                    }
                    .padding(.top, 16)
                    
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            title: "Basic Info",
                            subtitle: "Name and location of your plant"
                        )
                        
                        VStack {
                            TextField("Name", text: $viewModel.name)
                                .textFieldStyle(.plain)
                                .padding()
                            
							Divider()
								.padding(.horizontal)
                            
							Divider()
								.padding(.horizontal)
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
                                schedule: $viewModel.wateringSchedule,
                                options: [.daily, .weekly, .biweekly, .monthly]
                            )
                            
                            Divider()
                                .padding(.horizontal)
                            
                            CareOptionRow(
                                icon: "arrow.triangle.2.circlepath",
                                iconColor: .green,
                                title: "Rotation",
                                schedule: $viewModel.rotationSchedule,
                                options: [.none, .weekly, .biweekly, .monthly]
                            )
                            
                            Divider()
                                .padding(.horizontal)
                            
                            CareOptionRow(
                                icon: "leaf.fill",
                                iconColor: .indigo,
                                title: "Fertilizer",
                                schedule: $viewModel.fertilizerSchedule,
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
                        
                        TextField("Care notes", text: $viewModel.notes, axis: .vertical)
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
                    Button(mode.saveButtonText) {
                        Task {
                            if mode == .add {
                                let plant = viewModel.createPlant()
                                if let image = image {
                                    try? await imageManager.saveImage(image, for: plant)
                                }
                                modelContext.insert(plant)
							} else if let plant = viewModel.plant {
                                viewModel.updatePlant()
                                if let image = image {
                                    try? await imageManager.saveImage(image, for: plant)
                                }
                            }
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(image: $image)
                    .ignoresSafeArea()
            }
            .task {
                if mode == .edit, let plant = viewModel.plant {
                    image = imageManager.loadImage(for: plant)
                }
            }
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

//#Preview {
//	PlantFormView(mode: .add)
//}
