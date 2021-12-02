//
//  StringExtension.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(_ arguments: CVarArg...) -> String {
        String(format: localized, locale: .current, arguments: arguments)
    }
    
    init?(htmlEncodedString: String) {
        guard let data = htmlEncodedString.data(using: .utf8) else { return nil }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else { return nil }
        self.init(attributedString.string)
    }
    
    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }
}
