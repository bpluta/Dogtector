//
//  LowPowerModeInfoView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct LowPowerModeInfoView: View {
    @Environment(\.modalMode) var modalMode
    
    @Binding var isLiveDetectionEnabled: Bool
    
    var image: Image = Theme.Image.lowBattery
    var gradient: Gradient = Gradient(colors: [
        Theme.Color.orange.color,
        Theme.Color.yellow.color
    ])
    
    var body: some View {
        InformationScreen(
            title: "LowPowerModeSheetTitle".localized,
            icon: image,
            gradient: gradient,
            dismissAction: dismiss,
            content: {
                Group {
                    PrimaryLabel()
                    DescriptionLabel()
                    Divider()
                        .padding(.top, 10)
                        .padding(.horizontal, 30)
                    SwitchCell(title: "LowPowerModeSheetEnableLiveDetectionSwitchTitle".localized, value: $isLiveDetectionEnabled)
                    Spacer(minLength: 0)
                }
            }
        ).navigationWithCloseButton()
    }
    
    @ViewBuilder
    private func PrimaryLabel() -> some View {
        Label(text: "LowPowerModeSheetSubtitle".localized)
    }
    
    @ViewBuilder
    private func DescriptionLabel() -> some View {
        Label(text: "LowPowerModeSheetCaption".localized)
            .foregroundColor(Theme.Color.gray.color)
    }
    
    @ViewBuilder
    private func SwitchCell(title: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 20) {
            Text(title)
                .font(.system(size: 16))
            Toggle("", isOn: value)
                .toggleStyle(SwitchToggleStyle(tint: Theme.Color.orange.color))
                .labelsHidden()
        }.padding(.vertical, isLargerDevice ? 10 : 5)
        .padding(.horizontal, 10)
    }
    
    @ViewBuilder
    private func Label(text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .multilineTextAlignment(.center)
            .padding(.horizontal, isLargerDevice ? 20 : 0)
    }
}

extension LowPowerModeInfoView {
    private func dismiss() {
        modalMode.wrappedValue = false
    }
}

#if DEBUG
struct LowBatteryInfoPreview: PreviewProvider {
    @State private static var isLiveDetectionEnabled: Bool = true
    
    static var previews: some View {
        LowPowerModeInfoView(isLiveDetectionEnabled: $isLiveDetectionEnabled)
    }
}
#endif
