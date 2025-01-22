//
//  CelebrationView.swift
//  Verdant
//
//  Created by Richard Kolasa on 12/12/24.
//

import SwiftUI

struct CelebrationView: View {
	@State private var isAnimating = false
	let onDismiss: () -> Void
	
	let colors: [Color] = [
		.green,            // Fresh green
		.init(red: 0.2, green: 0.5, blue: 0.2),  // Forest green
		.init(red: 0.8, green: 0.6, blue: 0.1),  // Golden yellow
		.init(red: 0.5, green: 0.3, blue: 0.0),  // Bronze brown
		.init(red: 0.7, green: 0.8, blue: 0.3),  // Lime green
		.init(red: 0.4, green: 0.5, blue: 0.2),  // Olive green
		.init(red: 0.9, green: 0.4, blue: 0.1),  // Autumn orange
		.init(red: 0.3, green: 0.6, blue: 0.3)   // Sage green
	]
	
	var body: some View {
		ZStack {
			TimelineView(.animation) { _ in
				ZStack {
					ForEach(0..<50, id: \.self) { index in
						Image(systemName: "leaf.fill")
							.font(.system(size: 16))
							.foregroundStyle(colors.randomElement() ?? .green)
							.modifier(ConfettiAnimation(
								delay: Double(index) * 0.1,
								duration: .random(in: 2...4)
							))
					}
				}
			}
			
			VStack(spacing: 32) {
				VStack(spacing: 16) {
					Image(systemName: "checkmark.circle.fill")
						.font(.system(size: 48))
						.foregroundStyle(.primary)
						.scaleEffect(isAnimating ? 1.1 : 0.9)
					
					Text("All Done!")
						.font(.title.weight(.bold))
						.fontDesign(.rounded)
					
					Text("Your plants are happy and healthy.")
						.font(.body)
						.foregroundStyle(.secondary)
						.multilineTextAlignment(.center)
				}
				
				Button("Finish") {
					onDismiss()
				}
				.buttonStyle(.borderedProminent)
				.controlSize(.large)
			}
			.padding(32)
			.background(.ultraThinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.shadow(color: .black.opacity(0.1), radius: 10, y: 5)
			.padding(24)
		}
		.onAppear {
			isAnimating = true
		}
	}
}

#Preview {
	CelebrationView {
		
	}
}
