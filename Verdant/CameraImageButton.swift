//
//  CameraImageButton.swift
//  Verdant
//
//  Created by Richard Kolasa on 1/20/25.
//

import SwiftUI

struct CameraImageButton: View {
	@State var showingCamera: Bool = false
	@Binding var image: UIImage?
	var body: some View {
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
		.fullScreenCover(isPresented: $showingCamera) {
			CameraView(image: $image)
				.ignoresSafeArea()
		}
	}
}
