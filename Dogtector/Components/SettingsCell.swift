//
//  SettingsCell.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

class SettingsCellData<Destination: View>: Identifiable {
    enum ActionType {
        case button(action: () -> Void)
        case none
    }
    
    let id = UUID()
    
    var icon: SettingsCellIcon.IconType
    var title: String
    var subtitle: String?
    var action: ActionType
    
    init(icon: SettingsCellIcon.IconType, title: String, subtitle: String? = nil, action: ActionType = .none) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    @ViewBuilder
    var cell: some View {
        switch action {
        case .button(let action):
            Button<AnyView>(action: action, label: { cellBody })
        case .none:
            cellBody
        }
    }
    
    var cellBody: AnyView {
        AnyView(
            SettingsCell(iconType: icon, title: title, content: { EmptyView() })
        )
    }
}

struct SettingsCell<Content: View>: View {
    var iconType: SettingsCellIcon.IconType
    var title: String
    var subtitle: String?
    
    let content: Content
    
    init(iconType: SettingsCellIcon.IconType,
         title: String,
         subtitle: String? = nil,
         @ViewBuilder content: @escaping () -> Content)
    {
        self.iconType = iconType
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        HStack {
            SettingsCellIcon(iconType: iconType)
                .frame(width: 35)
                .padding(.vertical, 5)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Color.adaptiveBlack.color)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Theme.Color.gray.color)
                        .font(.system(size: 13))
                }
            }.padding(.vertical, 10)
            .padding(.horizontal, 5)
            Spacer()
            content
        }.contentShape(Rectangle())
    }
}

#if DEBUG
struct ButtonCellPreview: PreviewProvider {
    class CellData: Identifiable, ObservableObject {
        let id = UUID()
        
        let iconType: SettingsCellIcon.IconType
        let title: String
        let subtitle: String?
        
        init(iconType: SettingsCellIcon.IconType, title: String, subtitle: String?) {
            self.iconType = iconType
            self.title = title
            self.subtitle = subtitle
        }
    }
    
    @State static var toggleValue: Bool = true
    
    static let data: [CellData] = [
        CellData(
            iconType: .detection,
            title: "SettingsLiveDetectionSwitchTitle".localized,
            subtitle: "SettingsLiveDetectionSwitchDescription".localized
        ),
    ]
    
    static let menuData: [CellData] = [
        CellData(
            iconType: .donate,
            title: "SettingsDonationTitle".localized,
            subtitle: nil
        ),
        CellData(
            iconType: .about,
            title: "SettingsAboutAppTitle".localized,
            subtitle: nil
        ),
        CellData(
            iconType: .rate,
            title: "SettingsRateAppTitle".localized,
            subtitle: nil
        ),
        CellData(
            iconType: .reset,
            title: "SettingsResetToDefaultsTitle".localized,
            subtitle: nil
        ),
        CellData(
            iconType: .share,
            title: "SettingsShareAppTitle".localized,
            subtitle: nil
        )
    ]
    
    static var previews: some View {
        VStack(spacing: 0) {
            List {
                Section(header: Text("SettingsPreferencesSectionTitle".localized)) {
                    ForEach(data, id: \.id) { item in
                        ToggleSettingsCell(iconType: item.iconType, title: item.title, subtitle: item.subtitle, value: $toggleValue)
                    }
                }
                Section(header: Text("SettingsMenuSectionTitle".localized)) {
                    ForEach(menuData, id: \.id) { item in
                        ChevronSettingsCell(iconType: item.iconType, title: item.title, subtitle: item.subtitle)
                    }
                }
            }.listStyle(GroupedListStyle())
            .preferredColorScheme(.dark)
            .frame(width: 375)
            .previewLayout(.sizeThatFits)
        }
        
    }
}
#endif
