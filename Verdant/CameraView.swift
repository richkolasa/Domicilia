//
//  CameraView.swift
//  Verdant
//
//  Created by Richard Kolasa on 11/29/24.
//

import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
	@Binding var image: UIImage?
	@Environment(\.presentationMode) var presentationMode

	class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
		var parent: CameraView

		init(parent: CameraView) {
			self.parent = parent
		}

		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			if let uiImage = info[.originalImage] as? UIImage {
				// Create square version
				parent.image = uiImage
			}

			parent.presentationMode.wrappedValue.dismiss()
		}
		
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			parent.presentationMode.wrappedValue.dismiss()
		}
	}

	func makeCoordinator() -> Coordinator {
		return Coordinator(parent: self)
	}

	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.delegate = context.coordinator
		picker.sourceType = .camera
		
		return picker
	}

	func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
		// No update needed
	}
}
