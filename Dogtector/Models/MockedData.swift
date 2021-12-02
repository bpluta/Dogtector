//
//  MockedData.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation

#if DEBUG
extension DetectionClassInfo {
    fileprivate init(identifier: String, primaryName: String, alternativeNames: [String] = [], originCountries: [String] = [], infoURL: URL? = nil, licenceInfo: String? = nil) {
        self.identifier = identifier
        self.primaryName = primaryName
        self.alternativeNames = alternativeNames
        self.originCountries = originCountries
        self.infoURL = infoURL
        self.licenceInfo = licenceInfo
    }
    
    static let mocked: [DetectionClassInfo] = [
        DetectionClassInfo(
            identifier: "samoyed",
            primaryName: "Samoyed",
            alternativeNames: [
                "Bjelkier",
                "Samoiedskaya Sobaka"
            ],
            infoURL: URL(string: "https://en.wikipedia.org/wiki/Samoyed_dog"),
            licenceInfo: "Not by Joe Doe under Non Existing Licence (NEL)"
        ),
        DetectionClassInfo(
            identifier: "cardiganwelshcorgi",
            primaryName: "Cardigan Welsh Corgi",
            infoURL: URL(string: "https://en.wikipedia.org/wiki/Cardigan_Welsh_Corgi"),
            licenceInfo: "Not by Emily Williams under Completely Fake Mocked Up Licence (CFMUL)"
        ),
        DetectionClassInfo(
            identifier: "pug",
            primaryName: "Pug",
            alternativeNames: [
                "Chinese pug"
            ],
            infoURL: URL(string: "https://en.wikipedia.org/wiki/Pug"),
            licenceInfo: "Not by Emily Williams under Completely Fake Mocked Up Licence (CFMUL)"
        ),
        DetectionClassInfo(
            identifier: "shibainu",
            primaryName: "Shiba Inu",
            alternativeNames: [
                "Japanese Shiba Inu",
                "Japanese Small Size Dog",
                "Japanese Brushwood Dog",
                "Japanese Turf Dog",
                "Shiba Ken"
            ],
            infoURL: URL(string: "https://en.wikipedia.org/wiki/Samoyed_dog"),
            licenceInfo: "Not by John Smith under Another Licence That Not Exists (ALTNE)"
        ),
        DetectionClassInfo(
            identifier: "bordercollie",
            primaryName: "Border Collie",
            infoURL: URL(string: "https://en.wikipedia.org/wiki/Border_Collie"),
            licenceInfo: "Not by Jane Brown under Licence That Defenitely Is Not Real (LTDISNR)"
        ),
        DetectionClassInfo(
            identifier: "goldenretriever",
            primaryName: "Golden Retriever",
            alternativeNames: [
                "Yellow Retriever",
                "Russian Retriever"
            ],
            infoURL: URL(string: "https://en.wikipedia.org/wiki/Golden_Retriever"),
            licenceInfo: "Not by Emily Williams under Completely Fake Mocked Up Licence (CFMUL)"
        )
    ]
}
#endif
