//
//  VideoPreviewView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit
import AVFoundation
import Combine

#if PREVIEW
class VideoPreviewView: PreviewView {
    var onBufferUpdateAction: ((CVPixelBuffer) -> Void)?
    var onActionTrigger: (() -> Void)?
    
    private var player: AVOutputableQueuePlayer?
    private let playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    
    private lazy var displayLink: CADisplayLink = CADisplayLink(target: self, selector: #selector(readBuffer(_:)))
    
    private var cancelBag = CancelBag()
    
    override func updateSize(with imageSize: CGSize?, on canvasSize: CGSize) {
        super.updateSize(with: imageSize, on: canvasSize)
        playerLayer.frame = CGRect(size: canvasSize)
    }
    
    override func setupView() {
        setupPlayer()
        layer.addSublayer(playerLayer)
        layer.addSublayer(detectionLayer)
        setupDisplayLink()
    }
    
    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "benchmark_example", withExtension: "mp4") else {
            assertionFailure("Missing video file")
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        setupStatusObserver(for: playerItem)
        
        let player = AVOutputableQueuePlayer(items: [playerItem])
        let playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        self.player = player
        self.playerLooper = playerLooper
        
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
    }
    
    private func setupDisplayLink() {
        displayLink.preferredFramesPerSecond = 30
        displayLink.add(to: .main, forMode: .common)
    }
    
    private func setupStatusObserver(for playerItem: AVPlayerItem) {
        playerItem.publisher(for: \.status)
            .filter { $0 == .readyToPlay }
            .first()
            .sink(receiveValue: { [weak self] _ in
                self?.player?.play()
            }).store(in: cancelBag)
    }
    
    @objc private func readBuffer(_ sender: CADisplayLink) {
        guard let playerItemVideoOutput = player?.currentItem?.outputs.first as? AVPlayerItemVideoOutput else { return }
        let nextVSync = sender.timestamp + sender.duration
        let currentTime = playerItemVideoOutput.itemTime(forHostTime: nextVSync)

        let hasNewPixelBuffer = playerItemVideoOutput.hasNewPixelBuffer(forItemTime: currentTime)
        guard hasNewPixelBuffer, let pixelBuffer = playerItemVideoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) else { return }

        onBufferUpdateAction?(pixelBuffer)
    }
}

private extension VideoPreviewView {
    class AVOutputableQueuePlayer: AVQueuePlayer {
        override func insert(_ item: AVPlayerItem, after afterItem: AVPlayerItem?) {
            if item.outputs.isEmpty {
                let videoOutput = AVPlayerItemVideoOutput(outputSettings: [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA])
                item.add(videoOutput)
            }
            super.insert(item, after: afterItem)
        }
    }
}
#endif
