//
//  LicenceCell.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct LicenceCell: View {
    let subjects: [String]
    let licenceInfo: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(subjectInfo)
                .font(.system(size: 14))
                .foregroundColor(Theme.Color.gray.color)
            Text(licenceInfo)
                .font(.system(size: 16, weight: .bold))
        }.padding(10)
    }
    
    var subjectInfo: String {
        subjects.joined(separator: ", ")
    }
}

#if DEBUG
struct LicenceCellPreview: PreviewProvider {
    static var data: [DetectionClassInfo] {
        let dictionary = Dictionary(grouping: DetectionClassInfo.mocked, by: { $0.licenceInfo })
        let max = dictionary.max(by: {$0.value.count < $1.value.count})?.value.count ?? 0
        guard
            let mostFrequentItem = dictionary.filter({ $0.value.count == max }).first,
            let mostFrequentLicence = mostFrequentItem.value.first?.licenceInfo
        else { return [] }
        
        return DetectionClassInfo.mocked.filter { item in
            item.licenceInfo == mostFrequentLicence
        }
    }
    
    static var subjects: [String] {
        data.map(\.primaryName)
    }
    
    static var licenceInfo: String {
        data.first?.licenceInfo ?? ""
    }
    
    static var previews: some View {
        LicenceCell(
            subjects: subjects,
            licenceInfo: licenceInfo
        )
        .frame(width: 375)
        .previewLayout(.sizeThatFits)
    }
}
#endif
