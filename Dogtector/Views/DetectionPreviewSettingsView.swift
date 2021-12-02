//
//  DetectionPreviewSettingsView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

class DetectionPreviewSettings: ObservableObject {
    @Published var isAnnotationEnabled: Bool = AppDefaults.showAnnotationLabel
    @Published var isDetectionFrameEnabled: Bool = AppDefaults.showAnnotationFrame
    @Published var detectionFrameColor: Color = AppDefaults.annotationFrameColor.color
    @Published var annotationSize: CGFloat = AppDefaults.annotationLabelSize
}

struct DetectionPreviewSettingsView: View {
    @Environment(\.injected) private var injected: DependencyContainer
    
    @ObservedObject var settings: DetectionPreviewSettings
    @Binding var isLiveDetectionEnabled: Bool
    
    var cancelBag = CancelBag()
    
    var body: some View {
        VStack(spacing: 10) {
            LiveDetectionWarning()
            Section(title: "SettingsOverlayFrameColor".localized, isEnabled: isFrameColorEditEnabled) {
                ColorPickerCell(selectedColor: $settings.detectionFrameColor)
                    .padding(.vertical, 10)
                    .cornerRadius(10)
            }
            Section(title: "SettingsOverlayAnnotationSize".localized, isEnabled: isAnnotationSizeEditEnabled) {
                Slider(value: $settings.annotationSize, in: 0.5...1.5)
                    .accentColor(Theme.Color.primary.color)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 5)
                    .cornerRadius(10)
                    .id(isAnnotationSizeEditEnabled ? 1 : 0)
            }
            Section(isEnabled: isLiveDetectionEnabled) {
                VStack {
                    SwitchCell(title: "SettingsOverlayShowDetectionFrameSwitchTitle".localized, value: $settings.isDetectionFrameEnabled)
                    Divider()
                    SwitchCell(title: "SettingsOverlayShowDetectionAnnotationSwitchTitle".localized, value: $settings.isAnnotationEnabled)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 5)
                .cornerRadius(10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .onAppear(perform: setupSettingsSaving)
    }
    
    @ViewBuilder
    private func LiveDetectionWarning() -> some View {
        if !isLiveDetectionEnabled {
            HStack(spacing: 10) {
                Theme.Image.warning
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Theme.Color.yellow.color)
                    .frame(width: 20, height: 20)
                Text("SettingsOverlayLiveDetectionDisabledMessage".localized)
                Spacer()
                Button(action: enableLiveDetection, label: {
                    Text("GlobalEnable".localized)
                        .font(.subheadline)
                        .foregroundColor(Theme.Color.black.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.Color.yellow.color.cornerRadius(15))
                }).buttonStyle(.plain)
            }.padding(.vertical, 5)
            .drawingGroup()
        }
    }
    
    @ViewBuilder
    private func Section<Content: View>(title: String? = nil, isEnabled: Bool = true, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            if let title = title {
                HStack {
                    Text(title.uppercased())
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                        .opacity(isEnabled ? 1.0 : 0.5)
                    Spacer()
                }
            }
            content()
                .disabled(!isEnabled)
        }
    }
    
    @ViewBuilder
    private func SwitchCell(title: String, value: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .opacity(isLiveDetectionEnabled ? 1 : 0.5)
            Spacer()
            Toggle("", isOn: value)
                .disabled(!isLiveDetectionEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Theme.Color.primary.color))
                .labelsHidden()
        }.padding(.vertical, 5)
    }
}

extension DetectionPreviewSettingsView {
    private var isFrameColorEditEnabled: Bool {
        isLiveDetectionEnabled && settings.isDetectionFrameEnabled
    }
    
    private var isAnnotationSizeEditEnabled: Bool {
        isLiveDetectionEnabled && settings.isAnnotationEnabled
    }
    
    private func enableLiveDetection() {
        isLiveDetectionEnabled = true
        injected.appState[\.savedState.liveDetection] = true
    }
    
    private func setupSettingsSaving() {
        settings.$detectionFrameColor
            .map { UIColor($0) }
            .compactMap(\.hexString)
            .removeDuplicates()
            .sink { newValue in
                injected.appState[\.savedState.annotationFrameColor] = newValue
            }.store(in: cancelBag)

        settings.$isDetectionFrameEnabled
            .removeDuplicates()
            .sink(receiveValue: { newValue in
                injected.appState[\.savedState.showAnnotationFrame] = newValue
            }).store(in: cancelBag)

        settings.$isAnnotationEnabled
            .removeDuplicates()
            .sink(receiveValue: { newValue in
                injected.appState[\.savedState.showAnnotationLabel] = newValue
            }).store(in: cancelBag)

        settings.$annotationSize
            .map { Double($0) }
            .removeDuplicates()
            .sink(receiveValue: { newValue in
                injected.appState[\.savedState.annotationLabelSize] = newValue
            }).store(in: cancelBag)
    }
}

#if DEBUG
struct DetectionPreviewSettingsPreview: PreviewProvider {
    @ObservedObject private static var settings = DetectionPreviewSettings()
    @State private static var isLiveDetectionEnabled: Bool = true

    static var previews: some View {
        DetectionPreviewSettingsView(settings: settings, isLiveDetectionEnabled: .constant(true))
                .background(Theme.Color.listCell.color)
                .colorScheme(.dark)
    }
}
#endif
