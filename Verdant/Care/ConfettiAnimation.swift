//
//  ConfettiAnimation.swift
//  Verdant
//
//  Created by Richard Kolasa on 12/12/24.
//

import SwiftUI

struct ConfettiAnimation: ViewModifier {
	let delay: Double
	let duration: Double
	@State private var isAnimating = false
	
	func body(content: Content) -> some View {
		content
			.offset(x: isAnimating ? .random(in: -150...150) : 0,
					y: isAnimating ? 400 : -100)
			.rotationEffect(.degrees(isAnimating ? .random(in: -360...360) : 0))
			.onAppear {
				DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
					withAnimation(
						.linear(duration: duration)
						.repeatForever(autoreverses: false)
					) {
						isAnimating = true
					}
				}
			}
	}
}
