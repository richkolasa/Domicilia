import SwiftUI
import Observation

@Observable
class SettingsCoordinator {
    var isShowingSettings = false
    
    func showSettings() {
        isShowingSettings = true
    }
} 