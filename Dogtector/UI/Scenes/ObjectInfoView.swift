//
//  ObjectInfoView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct ObjectInfoView: View {
    @Environment(\.modalMode) private var modalMode
    @Environment(\.injected) private var injected: DependencyContainer
    
    @State private var isSheetPresented: Bool = false
    
    var object: DetectionClassInfo?
    var accuracy: Float
    var shouldShowCloseButton: Bool
    
    init(object: DetectionClassInfo?, accuracy: Float, shouldShowCloseButton: Bool = true) {
        self.object = object
        self.accuracy = accuracy
        self.shouldShowCloseButton = shouldShowCloseButton
    }
    
    var body: some View {
        ScrollView {
            VStack {
                DetectionInfoBox(
                    title: title,
                    subtitle: subtitle,
                    accuracy: accuracy
                ) {
                    ObjectFullImage
                        .resizable()
                        .scaledToFit()
                }
                VStack(spacing: 20) {
                    ForEach(sections, id: \.id) { section in
                        getComponent(for: section.type)
                            .modifier(SectionStyle())
                    }
                }
            }.padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                Theme.Color.listBackgroundInverted.color
                    .ignoresSafeArea()
            )
        }
        .navigationBarTitle(title, displayMode: .inline)
        .navigationWithCloseButton()
        .sheet(isPresented: $isSheetPresented, content: moreInfo)
    }
    
    private var ObjectFullImage: Image {
        if let image = object?.image {
            return Image(uiImage: image)
        } else {
            return Image("")
        }
    }
}

// MARK: Sections
private extension ObjectInfoView {
    var sections: [Section] {
        var sections = [Section]()
        if !alternativeNames.isEmpty {
            sections.append(Section(type: .alternativeNames))
        }
        if !originCountries.isEmpty {
            sections.append(Section(type: .originCountries))
        }
        if let _ = object?.infoURL {
            sections.append(Section(type: .moreInfo))
        }
        return sections
    }
    
    @ViewBuilder
    private func getComponent(for section: SectionType) -> some View  {
        switch section {
        case .alternativeNames:
            AlternativeNames()
        case .originCountries:
            OriginCountries()
        case .moreInfo:
            MoreInfo()
        }
    }
    
    @ViewBuilder
    private func AlternativeNames() -> some View {
        ArrayDataSection(
            title: "ObjectDetailsAlternativeNamesHeaderTitle".localized,
            data: alternativeNames
        )
    }
    
    @ViewBuilder
    private func OriginCountries() -> some View {
        ArrayDataSection(
            title: "ObjectDetailsOriginCountriesHeaderTitle".localized,
            data: originCountries
        )
    }
    
    @ViewBuilder
    private func MoreInfo() -> some View {
        HStack {
            Text("ObjectDetailsLearnMoreButtonTitle".localized)
            Spacer()
            Theme.Image.chevronRight
                .foregroundColor(Theme.Color.gray.color)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: showMoreInfo)
    }
    
    @ViewBuilder
    private func ArrayDataSection(title: String, data: [IdentifiableContainer<String>]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundColor(Theme.Color.gray.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 5)
            Divider()
            ForEach(data, id: \.id) { item in
                Text(item.content)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Helpers
extension ObjectInfoView {
    private var title: String {
        object?.primaryName ?? "ObjectDetailsNoNameTitle".localized
    }
    
    private var subtitle: String {
        "ObjectDetailsDetectionAccuracyInfo".localized(accuracy.detailedPercentageString)
    }
    
    private var alternativeNames: [IdentifiableContainer<String>] {
        object?.alternativeNames.map { IdentifiableContainer(content: $0) } ?? []
    }
    
    private var originCountries: [IdentifiableContainer<String>] {
        object?.originCountries.map { IdentifiableContainer(content: $0) } ?? []
    }
    
    private func showMoreInfo() {
        isSheetPresented = true
    }
    
    @ViewBuilder
    private func moreInfo() -> some View {
        if let url = object?.infoURL {
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
}

// MARK: Models
extension ObjectInfoView {
    struct Section: Identifiable {
        let type: SectionType
        let id = UUID()
    }
    
    enum SectionType {
        case alternativeNames
        case originCountries
        case moreInfo
    }
    
    struct SectionStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(.all, 20)
                .background(Theme.Color.listCellInverted.color)
                .cornerRadius(10)
        }
    }
}

#if DEBUG
struct ObjectInfoPreview: PreviewProvider {
    static var previews: some View {
        ObjectInfoView(object: AppState.preview.detectorData.classInfo.first, accuracy: 0.65)
    }
}
#endif
