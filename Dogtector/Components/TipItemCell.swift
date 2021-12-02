//
//  TipItemCell.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct TipItemCell: View {
    let isLoading: Bool
    let title: String?
    let description: String?
    let price: String?
    
    init(title: String?, description: String?, price: String?) {
        self.isLoading = false
        self.title = title
        self.description = description
        self.price = price
    }
    
    init() {
        self.isLoading = true
        self.title = nil
        self.description = nil
        self.price = nil
    }
    
    var body: some View {
        Content()
            .padding(20)
            .background(Theme.Color.adaptiveLighterGray.color.cornerRadius(15))
    }
    
    @ViewBuilder
    private func Content() -> some View {
        if isLoading {
            LoadingPlaceholder()
        } else {
            DataContent()
        }
    }
    
    @ViewBuilder
    private func LoadingPlaceholder() -> some View {
        LoadingPlaceholderMask()
            .overlay(
                LoadingShimmer(appearance: .light)
                    .mask(LoadingPlaceholderMask())
            )
    }
    
    @ViewBuilder
    private func LoadingPlaceholderMask() -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 7) {
                Rectangle().fill(Theme.Color.black.color)
                    .frame(width: 140, height: 16)
                Rectangle().fill(Theme.Color.black.color)
                    .frame(width: 170, height: 14)
                Rectangle().fill(Theme.Color.black.color)
                    .frame(width: 100, height: 14)
            }
            Spacer()
            Rectangle().fill(Theme.Color.black.color)
                .frame(width: 60, height: 30)
        }
    }
    
    @ViewBuilder
    private func DataContent() -> some View {
        HStack {
            Info()
            Spacer(minLength: 15)
            PriceTag()
        }
    }
    
    @ViewBuilder
    private func PriceTag() -> some View {
        if let price = price {
            Text(price)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Color.primaryContrastive.color)
                .padding(7)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Theme.Color.primaryContrastive.color, lineWidth: 2)
                )
        }
    }
    
    @ViewBuilder
    private func Info() -> some View {
        VStack(alignment: .leading, spacing: 5) {
            if let title = title {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let description = description {
                Text(description)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#if DEBUG
struct TipItemCellPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            TipItemCell(
                title: "Tip 1",
                description: "Lorem ipsum dolor sit amet",
                price: "$0.99"
            )
            TipItemCell(
                title: "Tip 2",
                description: "Lorem ipsum dolor sit amet",
                price: "$3.99"
            )
            TipItemCell(
                title: "Tip 3",
                description: "Lorem ipsum dolor sit amet",
                price: "$6.99"
            )
            Spacer()
        }.padding(.horizontal, 40)
    }
}
#endif
