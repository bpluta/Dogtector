//
//  LicenceInfoView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

// MARK: - Models
extension LicenceInfoView {
    class ViewModel: ObservableObject {
        @Published var licences: [LicenceInfoData] = []
    }
    
    struct LicenceInfoData: Identifiable {
        let id = UUID()
        let subjects: [String]
        let licence: String
    }
}

// MARK: - View
struct LicenceInfoView: View {
    @Environment(\.injected) private var injected: DependencyContainer
    @StateObject var viewModel = ViewModel()
    
    var cancelBag = CancelBag()
    
    var body: some View {
        List(viewModel.licences) { item in
            LicenceCell(subjects: item.subjects, licenceInfo: item.licence)
        }
        .navigationWithCloseButton()
        .navigationBarTitle("LicencesTitle".localized, displayMode: .large)
        .onAppear(perform: setupDetectionClassInfoSubject)
    }
}

// MARK: - Publishers
extension LicenceInfoView {
    var detectionClassInfoUpdates: AnyPublisher<[DetectionClassInfo],Never> {
        injected.appState.updates(for: \.detectorData.classInfo)
    }
}

// MARK: - Helpers
extension LicenceInfoView {
    private func setupDetectionClassInfoSubject() {
        setupLicenceData(from: injected.appState[\.detectorData].classInfo)
        injected.appState.updates(for: \.detectorData.classInfo)
            .sink { detectionClassInfo in
                setupLicenceData(from: detectionClassInfo)
            }.store(in: cancelBag)
    }
    
    private func setupLicenceData(from detectionClassData: [DetectionClassInfo]) {
        let groupedDetectionData = Dictionary(grouping: detectionClassData, by: \.licenceInfo)
        let licences = getPresentableLicences(from: groupedDetectionData)
        viewModel.licences = licences
    }
    
    private func getPresentableLicences(from groupedDetectionData: [String? : [DetectionClassInfo]]) -> [LicenceInfoData] {
        groupedDetectionData
            .filter { licence, _ in
                !["Pxhere","Pixabay"].contains(licence)
            }.compactMap { licence, detectionClasses in
                guard let licence = licence else { return nil }
                let subjects = detectionClasses.map(\.primaryName)
                return LicenceInfoData(subjects: subjects, licence: licence)
            }.sorted { firstItem, secondItem in
                firstItem.subjects.count > secondItem.subjects.count
            }
    }
}

#if DEBUG
struct LicenceInfoViewPreview: PreviewProvider {
    static var previews: some View {
        LicenceInfoView()
            .inject(DependencyContainer.preview)
    }
}
#endif
