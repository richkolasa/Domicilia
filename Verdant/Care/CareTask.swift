import Foundation

struct CareTask: Hashable, Identifiable {
    let id = UUID()
    let type: TaskType
    let plantName: String?
    
    enum TaskType: Hashable {
        case watering
        case rotation
		case fertilizing
    }
    
    var description: String {
        switch type {
        case .watering:
            return "Water"
        case .rotation:
            return "Rotate"
		case .fertilizing:
			return "Fertilize"
        }
    }
} 
