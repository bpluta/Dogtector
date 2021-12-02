//
//  SettingsCellIcon.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct SettingsCellIcon: View {
    let iconType: IconType
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 0.2 * geometry.size.width)
                    .fill(iconType.backgroundColor)
                iconType.image
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Theme.Color.white.color)
                    .padding(0.2 * geometry.size.width)
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
    
    enum IconType: Int, CaseIterable {
        case share
        case lowBattery
        case donate
        case about
        case rate
        case reset
        case detection
        case licence
        case debug
        case help
        
        var image: Image {
            switch self {
            case .share:
                return Theme.Image.share
            case .lowBattery:
                return Theme.Image.lowBattery
            case .donate:
                return Theme.Image.heart
            case .about:
                return Theme.Image.about
            case .rate:
                return Theme.Image.rateStar
            case .reset:
                return Theme.Image.resetArrow
            case .detection:
                return Theme.Image.viewfinder
            case .licence:
                return Theme.Image.copyright
            case .debug:
                return Theme.Image.device
            case .help:
                return Theme.Image.questionMark
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .share:
                return Theme.Color.green.color
            case .lowBattery:
                return Theme.Color.orange.color
            case .donate:
                return Theme.Color.red.color
            case .about:
                return Theme.Color.primary.color
            case .rate:
                return Theme.Color.yellow.color
            case .reset:
                return Theme.Color.blue.color
            case .detection:
                return Theme.Color.green.color
            case .licence:
                return Theme.Color.blue.color
            case .debug:
                return Theme.Color.gray.color
            case .help:
                return Theme.Color.orange.color
            }
        }
    }
}

#if DEBUG
struct SettingsCellIconPreview: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 10) {
            ForEach(SettingsCellIcon.IconType.allCases, id: \.rawValue) { item in
                SettingsCellIcon(iconType: item)
                    .frame(width: 50, alignment: .center)
            }
        }
        
    }
}
#endif
