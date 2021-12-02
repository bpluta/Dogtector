//
//  LinkMetadataManager.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import LinkPresentation

class LinkMetadataManager: NSObject {
    var linkMetadata: LPLinkMetadata
    
    init(linkMetadata: LPLinkMetadata = LPLinkMetadata()) {
        self.linkMetadata = linkMetadata
    }
}

// MARK: - UIActivityItemSource
extension LinkMetadataManager: UIActivityItemSource {
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        guard let url = AppDefaults.appStoreURL else { return linkMetadata }
        linkMetadata.originalURL = url
        linkMetadata.url = linkMetadata.originalURL
        linkMetadata.title = AppDefaults.appName
        
        if let icon = Bundle.main.icon?.sharedSheetPreviewIcon {
            let iconProvider = NSItemProvider(object: icon)
            linkMetadata.iconProvider = iconProvider
        }
        return linkMetadata
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any { "" }
    
    func activityViewController(_ activityViewController: UIActivityViewController,  itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        linkMetadata.url
    }
}
