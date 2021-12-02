//
//  DetectionDetails.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

// MARK: - Models
extension DetectionDetails {
    class ViewModel: ObservableObject {
        @Published var mode: Mode
        @Published var observations: [Observation]
        
        init(observations: [Observation], mode: Mode) {
            self.observations = observations.sorted(by: { $0.detectionIndex
                < $1.detectionIndex })
            self.mode = mode
        }
    }
    
    struct DetectionItem: Identifiable {
        let index: Int
        let observation: Observation
        let id = UUID()
    }
    
    enum Mode {
        case all
        case single
    }
}

// MARK: - View
struct DetectionDetails: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.modalMode) private var modalMode
    @Environment(\.injected) private var injected: DependencyContainer
    
    init(allObservations: [Observation]) {
        viewModel = ViewModel(observations: allObservations, mode: .all)
    }
    
    init(singleObservation: Observation?) {
        let observations = [singleObservation ?? nil].compactMap { $0 }
        viewModel = ViewModel(observations: observations, mode: .single)
    }
    
    var body: some View {
        ZStack {
            Theme.Color.listBackground.color
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(viewModel.observations) { observation in
                        DetectionTile(for: observation)
                    }
                }.padding(.vertical, 20)
            }.navigationTitle(Text(titleLabel))
            .navigationWithCloseButton()
        }
    }
    
    @ViewBuilder
    private func DetectionTile(for observation: Observation) -> some View {
        VStack {
            DetectionHeader(for: observation)
            ForEach(sectionItems(for: observation)) { item in
                Divider()
                    .padding(.horizontal, 5)
                DetectionCell(for: item)
            }
        }.padding(15)
        .background(Theme.Color.listCell.color)
        .cornerRadius(10)
        .padding(.horizontal, 10)
        .shadow(radius: 1)
    }
    
    @ViewBuilder
    private func DetectionHeader(for observation: Observation) -> some View {
        HStack {
            Theme.Image.viewfinder
                .resizable()
                .scaledToFit()
                .font(Font.title.weight(.semibold))
                .frame(width: 20, height: 20)
            Text("DetectionObservationTitle".localized(observation.detectionIndex.description))
                .font(.system(size: 18, weight: .semibold))
            Spacer()
            HStack(spacing: 4) {
                Theme.Image.accuracy
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                Text(observation.score.percentageString)
                    .font(.system(size: 12, weight: .regular))
                    
            }.foregroundColor(Theme.Color.white.color)
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(Theme.Color.primary.color)
            .cornerRadius(17)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 5)
        .padding(.bottom, 2)
    }
    
    @ViewBuilder
    private func DetectionCell(for observationItem: Observation.Item) -> some View {
        NavigationLink(
            destination: {
                ObjectInfoView(
                    object: getClassInfo(for: observationItem.classIndex),
                    accuracy: observationItem.score
                ).inject(injected)
                .environment(\.modalMode, modalMode)
            }, label: {
                DetectionItemCell(
                    title: getBreedName(for: observationItem.classIndex),
                    accuracy: observationItem.score,
                    chartContent: {
                        getImage(for: observationItem.classIndex).resizable()
                    }
                ).contentShape(Rectangle())
            }
        ).buttonStyle(.plain)
    }
}

// MARK: - Helpers
extension DetectionDetails {
    private var titleLabel: String {
        switch viewModel.mode {
        case .all:
            return "DetectionDetailsAllObservationsTitle".localized
        case .single:
            return "DetectionDetailsSingleObservationTitle".localized
        }
    }
    
    private func getImage(for classId: Int) -> Image {
        guard
            let classItem = getClassInfo(for: classId),
            let classImage = classItem.miniatureImage
        else { return Image("") }
        return Image(uiImage: classImage)
    }
    
    private func getClassInfo(for classId: Int) -> DetectionClassInfo? {
        let classInfo = injected.appState[\.detectorData.classInfo]
        guard classId >= 0 && classId < classInfo.count else { return nil }
        return classInfo[classId]
    }
    
    private func getBreedName(for classId: Int) -> String {
        guard let classItem = getClassInfo(for: classId) else { return "-" }
        return classItem.primaryName
    }
    
    private func sectionItems(for item: Observation) -> [Observation.Item] {
        item.objects.sorted(by: { $0.score > $1.score })
    }
}

#if DEBUG
struct DetectionDetailsPreview: PreviewProvider {
    static var previews: some View {
        DetectionDetails(allObservations: [Observation(detectionIndex: 0, rect: .init(), score: 0.85, objects: [
            .init(classIndex: 24, score: 0.9),
            .init(classIndex: 344, score: 0.4134),
            .init(classIndex: 120, score: 0.271)
        ])])
        .inject(.preview)
    }
}

#endif
