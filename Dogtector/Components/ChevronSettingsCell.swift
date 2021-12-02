//
//  ChevronSettingsCell.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

class ChevronSettingsCellData<Destination: View>: SettingsCellData<Destination> {
    override var cellBody: AnyView {
        AnyView(ChevronSettingsCell(iconType: icon, title: title, subtitle: subtitle))
    }
}

struct ChevronSettingsCell: View {
    let iconType: SettingsCellIcon.IconType
    let title: String
    let subtitle: String?
    
    var body: some View {
        SettingsCell(iconType: iconType, title: title, subtitle: subtitle) {
            Theme.Image.chevronRight
                .foregroundColor(Theme.Color.gray.color)
        }
    }
}

#if DEBUG
struct ChevronSettingsCellPreview: PreviewProvider {
    static var previews: some View {
        ChevronSettingsCell(iconType: .about, title: "SettingsAboutAppTitle".localized, subtitle: nil)
            .frame(width: 375)
            .previewLayout(.sizeThatFits)
    }
}
#endif
