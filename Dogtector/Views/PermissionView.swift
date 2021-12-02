//
//  PermissionView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct PermissionView: View {
    let currentPermissionStatus: Permission.Status

    let askForPermissionAction: () -> Void
    let pickImageAction: () -> Void
    let openSettingsAction: () -> Void
    
    var body: some View {
        VStack {
            CameraInfo()
            PermissionButton()
            Text("GlobalOrAlternative".localized.lowercased())
            PickImageButton()
        }.frame(width: 250)
        .foregroundColor(Theme.Color.white.color)
    }
    
    @ViewBuilder
    private func CameraInfo() -> some View {
        VStack {
            Theme.Image.camera
                .resizable()
                .scaledToFit()
                .font(Font.title.weight(.light))
                .frame(width: 80, height: 80)
            Text(info)
                .multilineTextAlignment(.center)
        }.padding(.vertical, 30)
    }
    
    @ViewBuilder
    private func PermissionButton() -> some View {
        switch currentPermissionStatus {
        case .notDetermined:
            StrokedCapsuleButton(text: "PermissionCameraAccessButtonTitle".localized, action: askForPermissionAction)
        default:
            StrokedCapsuleButton(text: "PermissionOpenSettingsButtonTitle".localized, action: openSettingsAction)
        }
    }
    
    @ViewBuilder
    private func PickImageButton() -> some View {
        StrokedCapsuleButton(text: "PermissionPickFromGalleryButtonTitle".localized, action: pickImageAction)
    }
}

extension PermissionView {
    private var info: String {
        switch currentPermissionStatus {
        case .notDetermined:
            return "PermissionAllowAccessInfoMessage".localized
        default:
            return "PermissionOpenSettingsInfoMessage".localized
        }
    }
}

#if DEBUG
struct PermissionPreview: PreviewProvider {
    static var previews: some View {
        PermissionView(
            currentPermissionStatus: .notDetermined,
            askForPermissionAction: {},
            pickImageAction: {},
            openSettingsAction: {}
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Color.black.color)
        .ignoresSafeArea()
    }
}
#endif
