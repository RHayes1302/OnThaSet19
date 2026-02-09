//
//  CameraPicker.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import UIKit

// MARK: - Camera Picker
/// UIKit camera wrapper for SwiftUI - allows capturing photos with device camera
struct CameraPicker: UIViewControllerRepresentable {
    
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Make UIViewController
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        
        return picker
    }
    
    // MARK: - Update UIViewController
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    // MARK: - Make Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }
    
    // MARK: - Coordinator Class
    /// Handles camera picker delegate methods
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        let onImagePicked: (UIImage) -> Void
        let dismiss: DismissAction
        
        init(onImagePicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }
        
        // MARK: Did Finish Picking
        /// Called when user takes a photo or cancels
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            dismiss()
        }
        
        // MARK: Did Cancel
        /// Called when user taps cancel
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
