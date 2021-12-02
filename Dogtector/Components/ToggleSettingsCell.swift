//
//  ToggleSettingsCell.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

class ToggleSettingsCellData<Destination: View>: SettingsCellData<Destination> {
    var value: Binding<Bool>
    
    init(icon: SettingsCellIcon.IconType, title: String, subtitle: String? = nil, value: Binding<Bool>, action: ActionType = .none) {
        self.value = value
        super.init(icon: icon, title: title, subtitle: subtitle, action: action)
    }
    
    override var cellBody: AnyView {
        AnyView(ToggleSettingsCell(iconType: icon, title: title, subtitle: subtitle, value: value))
    }
}

struct ToggleSettingsCell: View {
    let iconType: SettingsCellIcon.IconType
    let title: String
    let subtitle: String?
    @Binding var value: Bool
    
    var body: some View {
        SettingsCell(iconType: iconType, title: title, subtitle: subtitle) {
            Toggle("", isOn: $value)
                .labelsHidden()
        }
    }
}

#if DEBUG
struct ToggleSettingsCellPreview: PreviewProvider {
    @State static var toggleValue = true
    
    static var previews: some View {
        ToggleSettingsCell(iconType: .about, title: "SettingsAboutAppTitle".localized, subtitle: nil, value: $toggleValue)
            .frame(width: 375)
            .previewLayout(.sizeThatFits)
    }
}
#endif
