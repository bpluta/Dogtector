//
//  DetectorInteractor.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Combine
import Vision
import SwiftUI
import AVFoundation

protocol DetectorLogic {
    #if BENCHMARK
    var fpsPublisher: AnyPublisher<Double,Never> { get }
    #endif
    var predictionsPublisher: AnyPublisher<[Observation],Never> { get }
    
    func loadDetectionData()
    func setupVision() -> AnyPublisher<Void, DetectorError>
    func detect(pixelBuffer: CVPixelBuffer, in rect: CGRect, orientation: OutputOrientation) -> AnyPublisher<[Observation], DetectorError>
}

typealias ObservationSubject = PassthroughSubject<[Observation], Never>
typealias ObservationPublisher = AnyPublisher<[Observation], Never>

class DetectorInteractor: DetectorLogic {
    let appState: Store<AppState>
    let detectionDataRepository: DetectorDataRepository
    
    private var model: VNCoreMLModel?
    private lazy var objectDecoder: ObjectDecoder = setupDecoder()
    
    private var detectionQueue = DispatchQueue(label: "com.detectorInteractor.detectionQueue", qos: .userInitiated)
    private let currentDetectionSyncGroup = DispatchGroup()
    private var isCurrentlyDetecting: Bool = false
    
    private var cancelBag = CancelBag()
    
    #if BENCHMARK
    private var framesDone = 0
    private var frameCapturingStartTime = CACurrentMediaTime()
    private var startTime = CACurrentMediaTime()
    
    var fpsPublisher: AnyPublisher<Double,Never> { fpsSubject.eraseToAnyPublisher() }
    private let fpsSubject = PassthroughSubject<Double,Never>()
    #endif
    
    var predictionsPublisher: AnyPublisher<[Observation],Never> { predictionsSubject.eraseToAnyPublisher() }
    private let predictionsSubject = PassthroughSubject<[Observation],Never>()
    
    init(appState: Store<AppState>, repository: DetectorDataRepository) {
        self.appState = appState
        self.detectionDataRepository = repository
    }
    
    // MARK: - Interface implementations
    func loadDetectionData() {
        detectionDataRepository.loadClassDetectionData()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                default: break
                }
            }, receiveValue: { [weak self] detectionData in
                self?.appState[\.detectorData.classInfo] = detectionData
            }).store(in: cancelBag)
    }
    
    func setupVision() -> AnyPublisher<Void, DetectorError> {
        Future { [weak self] promise in
            self?.detectionQueue.async {
                guard let modelURL = Bundle.main.url(forResource: ModelInfo.assetName, withExtension: ModelInfo.assetExtension) else {
                    return promise(.failure(.modelNotConfigured))
                }
                do {
                    let configuration = MLModelConfiguration()
                    configuration.computeUnits = .all
                    
                    let loadedModel = try MLModel(contentsOf: modelURL, configuration: configuration)
                    self?.model = try VNCoreMLModel(for: loadedModel)
                    
                    let modelInputWidth = loadedModel.modelDescription.inputDescriptionsByName[ModelInfo.inputSizeKey]?.imageConstraint?.pixelsWide
                    let modelInputHeight = loadedModel.modelDescription.inputDescriptionsByName[ModelInfo.inputSizeKey]?.imageConstraint?.pixelsHigh
                    
                    self?.objectDecoder.inputHeight = modelInputHeight
                    self?.objectDecoder.inputWidth = modelInputWidth
                    
                    return promise(.success(()))
                } catch {
                    return promise(.failure(.modelNotConfigured))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func detect(pixelBuffer: CVPixelBuffer, in rect: CGRect, orientation: OutputOrientation) -> AnyPublisher<[Observation], DetectorError> {
        Future<[Any]? ,DetectorError> { [weak self] promise in
            self?.detectionQueue.async {
                guard let model = self?.model else {
                    return promise(.failure(.modelNotConfigured))
                }
                
                let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
                    return promise(.success(request.results))
                })
                request.imageCropAndScaleOption = .scaleFill
                
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
                do {
                    try imageRequestHandler.perform([request])
                } catch {
                    return promise(.failure(.detectionFailure))
                }
            }
        }.compactMap { results in
            results as? [VNCoreMLFeatureValueObservation]
        }.map { [weak self] results in
            self?.objectDecoder.process(results: results, in: rect, orientation: orientation) ?? []
        }
        #if BENCHMARK
        .map { [weak self] results in
            self?.measureFPS()
            return results
        }
        #endif
        .eraseToAnyPublisher()
    }
}

// MARK: - Helpers
extension DetectorInteractor {
    private func setupDecoder() -> ObjectDecoder {
        let device = AppDefaults.metalDevice
        let decoderType = ObjectDecoder.recommendedDecoder(for: device)
        let decoder = ObjectDecoder.initializeDecoder(type: decoderType, device: device)
        
        appState[\.detectorData.decoderType] = decoderType
        return decoder
    }
    
    #if BENCHMARK
    private func measureFPS() {
        framesDone += 1
        let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
        let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
        if frameCapturingElapsed > 1 {
            framesDone = 0
            frameCapturingStartTime = CACurrentMediaTime()
        }
        fpsSubject.send(currentFPSDelivered)
    }
    #endif
}

// MARK: - Stub
class StubDetectorLogic: DetectorLogic {
    #if BENCHMARK
    var fpsPublisher: AnyPublisher<Double, Never> { Empty().eraseToAnyPublisher() }
    #endif
    
    var predictionsPublisher: AnyPublisher<[Observation], Never> { Empty().eraseToAnyPublisher() }
    
    func loadDetectionData() { }
    
    func setupVision() -> AnyPublisher<Void, DetectorError> { Empty().eraseToAnyPublisher() }
    
    func detect(pixelBuffer: CVPixelBuffer, in rect: CGRect, orientation: OutputOrientation) -> AnyPublisher<[Observation], DetectorError> { Empty().eraseToAnyPublisher() }
}
