//
//  DetectionClassInfo.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit

struct DetectionClassInfo: Decodable, Equatable {
    var identifier: String
    var primaryName: String
    var alternativeNames: [String]
    var originCountries: [String]
    var infoURL: URL?
    var licenceInfo: String?
    
    var miniatureImage: UIImage?
    var image: UIImage? { UIImage(named: identifier) }
    
    private static var miniatureNameSuffix = "_miniature"
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let classIdentifier = try values.decode(String.self, forKey: .identifier)
        let nameString = try values.decodeIfPresent(String.self, forKey: .primaryName)
        let alternativeNamesArray = try values.decodeIfPresent([String].self, forKey: .alternativeNames)
        let originCountriesArray = try values.decodeIfPresent([String].self, forKey: .originCountries)
        let urlString = try values.decodeIfPresent(String.self, forKey: .infoURL)
        let licenceString = try values.decodeIfPresent(String.self, forKey: .licenceInfo)
        
        identifier = classIdentifier
        primaryName = nameString ?? classIdentifier
        alternativeNames = alternativeNamesArray ?? []
        originCountries = originCountriesArray ?? []
        infoURL = URL(string: urlString ?? "")
        licenceInfo = licenceString != nil ? String(htmlEncodedString: licenceString ?? "") : ""
        miniatureImage = UIImage(named: "\(identifier)\(Self.miniatureNameSuffix)")
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case primaryName = "name"
        case alternativeNames
        case originCountries = "origin"
        case infoURL = "url"
        case licenceInfo = "licence"
    }
}
