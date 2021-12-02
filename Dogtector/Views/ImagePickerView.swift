//
//  ImagePickerView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import UIKit
import Photos

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    
    var onImagePickedAction: (ImageData) -> Void
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}


// MARK: - Coordinator
extension ImagePicker {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }
    }
}

extension ImagePicker.Coordinator {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage = getImage(from: info) {
            parent.onImagePickedAction(pickedImage)
        }
        parent.presentationMode.wrappedValue.dismiss()
    }
    
    private func getImage(from info: [UIImagePickerController.InfoKey: Any]) -> PickedImage? {
        if let uiImage = info[.editedImage] as? UIImage {
            return PickedImage(image: uiImage)
        } else if let uiImage = info[.originalImage] as? UIImage {
            return PickedImage(image: uiImage)
        }
        return nil
    }
}
