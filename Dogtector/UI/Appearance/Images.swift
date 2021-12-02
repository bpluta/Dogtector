//
//  Images.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

extension Theme {
    enum Image {
        static var appIcon: SwiftUI.Image {
            SwiftUI.Image(AppDefaults.appIconBundleName)
        }
        
        static var chevronLeft: SwiftUI.Image {
            SwiftUI.Image(systemName: "chevron.left")
        }
        
        static var chevronRight: SwiftUI.Image {
            SwiftUI.Image(systemName: "chevron.right")
        }
        
        static var viewfinder: SwiftUI.Image {
            SwiftUI.Image(systemName: "viewfinder")
        }
        
        static var bolt: SwiftUI.Image {
            SwiftUI.Image(systemName: "bolt.fill")
        }
        
        static var heart: SwiftUI.Image {
            SwiftUI.Image(systemName: "heart")
        }
        
        static var about: SwiftUI.Image {
            SwiftUI.Image(systemName: "info.circle")
        }
        
        static var resetArrow: SwiftUI.Image {
            SwiftUI.Image(systemName: "arrow.counterclockwise")
        }
        
        static var rateStar: SwiftUI.Image {
            SwiftUI.Image(systemName: "star.leadinghalf.fill")
        }
        
        static var share: SwiftUI.Image {
            SwiftUI.Image(systemName: "square.and.arrow.up")
        }
        
        static var questionMark: SwiftUI.Image {
            SwiftUI.Image(systemName: "questionmark.circle")
        }
        
        static var copyright: SwiftUI.Image {
            SwiftUI.Image(systemName: "c.circle")
        }
        
        static var device: SwiftUI.Image {
            SwiftUI.Image(systemName: "iphone")
        }
        
        static var lowBattery: SwiftUI.Image {
            SwiftUI.Image(systemName: "battery.25")
        }
        
        static var pictures: SwiftUI.Image {
            SwiftUI.Image(systemName: "photo.on.rectangle.angled")
        }
        
        static var list: SwiftUI.Image {
            SwiftUI.Image(systemName: "list.bullet")
        }
        
        static var eye: SwiftUI.Image {
            SwiftUI.Image(systemName: "eye")
        }
        
        static var slashedEye: SwiftUI.Image {
            SwiftUI.Image(systemName: "eye.slash")
        }
        
        static var save: SwiftUI.Image {
            SwiftUI.Image(systemName: "square.and.arrow.down")
        }
        
        static var more: SwiftUI.Image {
            SwiftUI.Image(systemName: "ellipsis.circle")
        }
        
        static var accuracy: SwiftUI.Image {
            SwiftUI.Image(systemName: "dot.circle.and.cursorarrow")
        }
        
        static var success: SwiftUI.Image {
            SwiftUI.Image(systemName: "checkmark.circle.fill")
        }
        
        static var failure: SwiftUI.Image {
            SwiftUI.Image(systemName: "xmark.octagon.fill")
        }
        
        static var warning: SwiftUI.Image {
            SwiftUI.Image(systemName: "exclamationmark.triangle.fill")
        }
        
        static var filledHeart: SwiftUI.Image {
            SwiftUI.Image(systemName: "heart.fill")
        }
        
        static var info: SwiftUI.Image {
            SwiftUI.Image(systemName: "info.circle.fill")
        }
        
        static var xmark: SwiftUI.Image {
            SwiftUI.Image(systemName: "xmark")
        }
        
        static var camera: SwiftUI.Image {
            SwiftUI.Image(systemName: "camera")
        }
        
        static var shield: SwiftUI.Image {
            SwiftUI.Image(systemName: "checkmark.shield")
        }
        
        static var magnifyingGlass: SwiftUI.Image {
            SwiftUI.Image(systemName: "magnifyingglass")
        }
        
        static var sammyDog: SwiftUI.Image {
            SwiftUI.Image("sammy")
        }
        
        static var dogIllustration: SwiftUI.Image {
            SwiftUI.Image("dog_illustration")
        }
    }
}
