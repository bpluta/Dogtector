//
//  DetectionItemCell.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct DetectionItemCell<Content: View>: View {
    var title: String
    var accuracy: Float

    let chartContent: Content

    init(title: String, accuracy: Float, @ViewBuilder chartContent: @escaping () -> Content) {
        self.title = title
        self.chartContent = chartContent()
        self.accuracy = accuracy
    }

    var body: some View {
        HStack {
            ObjectImage()
            ObjectLabel()
            Spacer()
            Chevron()
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 5)
    }
    
    @ViewBuilder
    private func ObjectLabel() -> some View{
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            HStack(spacing: 3) {
                Theme.Image.accuracy
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                Text(accuracy.percentageString)
                    .font(.system(size: 13))
            }
        }.padding(.horizontal, 5)
    }
    
    @ViewBuilder
    private func Chevron() -> some View {
        Theme.Image.chevronRight
            .resizable()
            .scaledToFit()
            .frame(width: 15, height: 15)
            .foregroundColor(Theme.Color.gray.color)
    }
    
    @ViewBuilder
    private func ObjectImage() -> some View {
        RingChart(progress: accuracy, thickness: 6) {
            chartContent
        }
        .frame(width: 55, height: 55)
        .shadow(radius: 1)
    }
}

#if DEBUG
struct DetectionItemCellPreview: PreviewProvider {
    static var previews: some View {
        DetectionItemCell(title: "Border collie", accuracy: 0.64, chartContent: { Image("bordercollie_miniature").resizable() })
            .frame(width: 375)
            .previewLayout(.sizeThatFits)
    }
}
#endif
