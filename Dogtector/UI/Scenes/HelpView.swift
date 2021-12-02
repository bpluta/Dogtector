//
//  HelpView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

// MARK: - Models
extension HelpView {
    class ViewModel: ObservableObject {
        @Published var answers: [AnswerData] = []
    }
    
    struct AnswerData: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }
}

// MARK: - View
struct HelpView: View {
    private var answers: [AnswerData] = [
        AnswerData(
            question: "FAQBreedAmountQuestion".localized,
            answer: "FAQBreedAmountAnswer".localized
        ),
        AnswerData(
            question: "FAQLiveDetectionDisabledQuestion".localized,
            answer: "FAQLiveDetectionDisabledAnswer".localized
        ),
        AnswerData(
            question: "FAQReliabilityQuestion".localized,
            answer: "FAQReliabilityAnswer".localized
        ),
        AnswerData(
            question: "FAQBestResultsQuestion".localized,
            answer: "FAQBestResultsAnswer".localized
        ),
        AnswerData(
            question: "FAQMixedBreedsQuestion".localized,
            answer: "FAQMixedBreedsAnswer".localized
        ),
        AnswerData(
            question: "FAQDeniedPermissionQuestion".localized,
            answer: "FAQDeniedPermissionAnswer".localized
        ),
        AnswerData(
            question: "FAQSlowDetectionQuestion".localized,
            answer: "FAQSlowDetectionAnswer".localized
        ),
    ]
    
    var body: some View {
        List(answers) { item in
            AnswerCell(question: item.question, answer: item.answer)
        }.navigationWithCloseButton()
        .navigationBarTitle("FAQTitle".localized, displayMode: .large)
    }
    
    @ViewBuilder
    private func AnswerCell(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question)
                .font(.system(size: 20, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
            Text(answer)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Theme.Color.gray.color)
                .fixedSize(horizontal: false, vertical: true)
        }.padding(10)
    }
}


#if DEBUG
struct HelpPreview: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
#endif
