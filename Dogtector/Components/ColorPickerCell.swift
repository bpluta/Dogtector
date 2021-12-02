//
//  ColorPickerCell.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct ColorPickerCell: View {
    @Environment(\.isEnabled) private var isEnabled
    @Binding var selectedColor: Color
    @State var colors = Self.getColors()
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(colors, id: \.id) { color in
                ColorButton(color: color.content, isSelected: isSelected(color.content))
                    .frame(maxWidth: .infinity)
            }
        }.padding(.vertical, 5)
    }
    
    @ViewBuilder
    private func ColorButton(color: Color, isSelected: Bool) -> some View {
        Button(action: { selectedColor = color }) {
            Circle()
                .fill(color)
                .frame(width: 25, height: 25).padding(3)
                .shadow(color: Theme.Color.lightShadow.color, radius: 3)
                .overlay(isSelected ? SelectionStroke() : nil)
                .opacity(!isEnabled ? 0.5 : 1)
        }
    }
    
    @ViewBuilder
    private func SelectionStroke() -> some View {
        Circle()
            .strokeBorder(Theme.Color.lightGray.color, lineWidth: 4)
    }
}

// MARK: - Helpers
extension ColorPickerCell {
    private static func getColors() -> [IdentifiableContainer<Color>] {
        AppDefaults.colorPickerColors.map { color in
            IdentifiableContainer(content: color)
        }
    }
    
    private func isSelected(_ color: Color) -> Bool {
        guard let comparedHexColor = UIColor(color).hexString,
              let selectedHexColor = UIColor(selectedColor).hexString
        else { return false }
        return comparedHexColor == selectedHexColor
    }
}

#if DEBUG
struct ColorPickerCellPreview: PreviewProvider {
    @State static var selectedColor: Color = AppDefaults.annotationFrameColor.color
    
    static var previews: some View {
        ColorPickerCell(selectedColor: $selectedColor)
            .frame(width: 320)
            .previewLayout(.sizeThatFits)
            .background(Theme.Color.lightBackgrouund.color)
        
    }
}
#endif
