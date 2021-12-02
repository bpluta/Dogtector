//
//  FrameDecoder.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct RawObservationFrame {
    let x: Float
    let y: Float
    let width: Float
    let height: Float
}

protocol FrameDecoder {
    func computeX(for observation: RawObservationFrame, width: CGFloat, scaleFactor: CGFloat) -> CGFloat
    func computeY(for observation: RawObservationFrame, height: CGFloat, scaleFactor: CGFloat) -> CGFloat
    func computeWidth(for observation: RawObservationFrame, scaleFactor: CGFloat) -> CGFloat
    func computeHeight(for observation: RawObservationFrame, scaleFactor: CGFloat) -> CGFloat
}

struct PortraitFrameDecoder: FrameDecoder {
    func computeX(for observation: RawObservationFrame, width: CGFloat, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.x - (observation.width / 2.0)) * scaleFactor
    }
    
    func computeY(for observation: RawObservationFrame, height: CGFloat, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.y - (observation.height / 2.0)) * scaleFactor
    }
    
    func computeWidth(for observation: RawObservationFrame, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.width) * scaleFactor
    }
    
    func computeHeight(for observation: RawObservationFrame, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.height) * scaleFactor
    }
}

struct LandscapeLeftFrameDecoder: FrameDecoder {
    let bounds: CGRect
    
    func computeX(for observation: RawObservationFrame, width: CGFloat, scaleFactor: CGFloat) -> CGFloat {
        (bounds.width - width) - CGFloat(observation.y - (observation.height / 2.0)) * scaleFactor
    }
    
    func computeY(for observation: RawObservationFrame, height: CGFloat, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.x - (observation.width / 2.0)) * scaleFactor
    }
    
    func computeWidth(for observation: RawObservationFrame, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.height) * scaleFactor
    }
    
    func computeHeight(for observation: RawObservationFrame, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.width) * scaleFactor
    }
}

struct LandscapeRightFrameDecoder: FrameDecoder {
    let bounds: CGRect
    
    func computeX(for observation: RawObservationFrame, width: CGFloat, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.y - (observation.height / 2.0)) * scaleFactor
    }
    
    func computeY(for observation: RawObservationFrame, height: CGFloat, scaleFactor: CGFloat) -> CGFloat {
        (bounds.height - height) - CGFloat(observation.x - (observation.width / 2.0)) * scaleFactor
    }
    
    func computeWidth(for observation: RawObservationFrame, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.height) * scaleFactor
    }
    
    func computeHeight(for observation: RawObservationFrame, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.width) * scaleFactor
    }
}

struct UpsideDownFrameDecoder: FrameDecoder {
    let bounds: CGRect
    
    func computeX(for observation: RawObservationFrame, width: CGFloat, scaleFactor: CGFloat) -> CGFloat {
        (bounds.width - width) - CGFloat(observation.x - (observation.width / 2.0)) * scaleFactor
    }
    
    func computeY(for observation: RawObservationFrame, height: CGFloat, scaleFactor: CGFloat) -> CGFloat {
        (bounds.height - height) - CGFloat(observation.y - (observation.height / 2.0)) * scaleFactor
    }
    
    func computeWidth(for observation: RawObservationFrame, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.width) * scaleFactor
    }
    
    func computeHeight(for observation: RawObservationFrame, scaleFactor: CGFloat) -> CGFloat {
        CGFloat(observation.height) * scaleFactor
    }
}
