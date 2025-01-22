import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext
    @Environment(WeatherManager.self) private var weatherManager
    @AppStorage("useCelsius") private var useCelsius = false
    @AppStorage("useKph") private var useKph = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Temperature", selection: $useCelsius) {
                        Text("°F").tag(false)
                        Text("°C").tag(true)
                    }
                    
                    Picker("Wind Speed", selection: $useKph) {
                        Text("mph").tag(false)
                        Text("km/h").tag(true)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
