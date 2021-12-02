//
//  DetectionInfoBox.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

extension VerticalAlignment {
    enum BottomImage: AlignmentID {
        static func defaultValue(in dimension: ViewDimensions) -> CGFloat {
            dimension[.bottom]
        }
        static let bottomImage = VerticalAlignment(BottomImage.self)
    }
}

struct DetectionInfoBox<Content: View>: View {
    var title: String
    var subtitle: String
    var accuracy: Float
    
    let content: Content
    let miniatureSize: CGFloat = 130
    
    init(title: String, subtitle: String, accuracy: Float, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.accuracy = accuracy
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: VerticalAlignment.BottomImage.bottomImage)) {
            ConentSheet()
            VStack(alignment: .center, spacing: 5) {
                Chart()
                BreedName()
                AccuracyDescription()
            }
            .padding(.horizontal, 20)
            .alignmentGuide(VerticalAlignment.BottomImage.bottomImage, computeValue: { dimension in
                dimension[VerticalAlignment.top] + miniatureSize / 3
            })
        }.padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func ConentSheet() -> some View {
        content
            .frame(alignment: .top)
            .cornerRadius(30, corners: [.bottomLeft, .bottomRight])
            .shadow(color: Theme.Color.lightShadow.color, radius: 5)
            .alignmentGuide(VerticalAlignment.BottomImage.bottomImage, computeValue: { dimension in
                dimension[.bottom]
            })
    }
    
    @ViewBuilder
    private func Chart() -> some View {
        RingChart(progress: accuracy, thickness: 18) {
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Text(accuracy.roundedPercentageString)
                        .font(.system(size: 100, weight: .bold))
                        .minimumScaleFactor(0.01)
                        .foregroundColor(Theme.Color.primary.color)
                    Spacer()
                }
                Spacer()
            }.background(Theme.Color.listBackgroundInverted.color)
        }.frame(width: miniatureSize, height: miniatureSize)
        .background(
            Theme.Color.listBackgroundInverted.color
                .clipShape(Circle())
        ).shadow(color: Theme.Color.lightShadow.color, radius: 3)
        .padding(.bottom, 10)
    }
    
    @ViewBuilder
    private func BreedName() -> some View {
        Text(title)
            .font(.system(size: 28, weight: .bold))
            .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    private func AccuracyDescription() -> some View {
        Text(subtitle)
            .font(.system(size: 16))
            .foregroundColor(Theme.Color.gray.color)
    }
}

#if DEBUG
struct DetectionInfoBoxPreview: PreviewProvider {
    static var previews: some View {
        DetectionInfoBox(
            title: "Some long dog breed name",
            subtitle: "ObjectDetailsDetectionAccuracyInfo".localized("74.00%"),
            accuracy: 0.74
        ) {
            Image("samoyed")
                .resizable()
                .scaledToFit()
        }
    }
}
#endif
