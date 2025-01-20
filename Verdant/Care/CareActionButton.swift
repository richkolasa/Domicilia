//
//  CareActionButton.swift
//  Verdant
//
//  Created by Richard Kolasa on 12/12/24.
//

import SwiftUI

struct CareActionButton: View {
	let title: String
	let systemImage: String
	let color: Color
	let isCompleted: Bool
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			HStack(spacing: 12) {
				Text(title)
					.fontWeight(.medium)
				
				Image(systemName: isCompleted ? "checkmark.circle.fill" : systemImage)
					.imageScale(.medium)
					.fontWeight(.semibold)
			}
			.padding(.horizontal, 18)
			.padding(.vertical, 12)
			.foregroundStyle(isCompleted ? Color.secondary : .white)
			.background(
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.fill(isCompleted ? .secondary.opacity(0.1) : color)
					.shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.stroke(isCompleted ? Color.secondary : color, lineWidth: 1)
			)
		}
		.disabled(isCompleted)
	}
}

#Preview {
	VStack {
		CareActionButton(title: "Water", systemImage: "drop.fill", color: .blue, isCompleted: false) {
			
		}
	}
	.frame(maxWidth: .infinity, maxHeight: .infinity)
	.background(.white)
	
}
