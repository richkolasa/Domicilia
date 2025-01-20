import SwiftUI
import StoreKit

struct TipJarView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Your support helps keep Domicilia growing 🌱")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack {
                    ProductView(id: "com.richardkolasa.verdant.smalltip") {
                        Text("🙏")
                    }
                    
                    ProductView(id: "com.richardkolasa.verdant.mediumtip") {
                        Text("😭")
                    }
                    
                    ProductView(id: "com.richardkolasa.verdant.largetip") {
                        Text("😳")
                    }
                }
                .productViewStyle(.compact)
				.padding()
				Spacer()
            }
            .navigationTitle("Tip Jar")
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
