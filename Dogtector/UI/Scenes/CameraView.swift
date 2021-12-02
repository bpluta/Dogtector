//
//  CameraView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine
import AVFoundation

// MARK: - Models
extension CameraView {
    class ViewModel: ObservableObject {
        @Published var mode: PreviewMode = .empty
        @Published var selectedPrediction: Observation?
        @Published var currentImage: PreviewedImage?
        @Published var presentedZoomValue: Double = 1.0
        @Published var detectionDescription: String = ""
        @Published var fps: Double = 0
        
        @Published var isLiveDetecitonEnabled = true
        @Published var isFlashEnabled = false
        @Published var areDetectionsVisible = true
        @Published var shouldDisplayObservations = true
        @Published var shouldAllowDetection = true
        @Published var shouldFreezeButtons: Bool = false
        
        @Published var isLoaderPresented: Bool = false
        @Published var isShutterOverlayDisplayed: Bool = false
        @Published var isSettingsScreenPresented = false
        @Published var areDetectionPreviewSettingsDisplayed = false
    }

    class ViewConfiguration: ObservableObject {
        var didDisplayLowPowerModeInfo = false
        var isConfigured: Bool = false
        var isCurrentlyDetecting: Bool = false
        
        var statusBag = StatusInfoBox.StatusBag()
        var statusPublisher = StatusSubject()
        var observationPublisher = ObservationSubject()
        
        var session = AVCaptureSession()
        var canvasSize = CGSize.zero
        var zoomState = ZoomState()
        var orientation = OutputOrientation.portarait
        
        var imagePicker: ImagePicker = ImagePicker(onImagePickedAction: { _ in })
    }
}

// MARK: - View
struct CameraView: View {
    @Environment(\.notificationPublisher) private var notificationPublisher: NotificationSubject
    @Environment(\.injected) private var injected: DependencyContainer
    
    @StateObject private var viewModel = ViewModel()
    @StateObject private var detectionPreviewSettings = DetectionPreviewSettings()
    @StateObject private var _configuration = ViewConfiguration()
    
    @State private var routingState = Routing()
    
    private var cancelBag = CancelBag()
    
    private var configurationQueue = DispatchQueue(label: "com.cameraView.configurationQueue")
    private var configuration: ViewConfiguration {
        get { configurationQueue.sync { _configuration } }
    }
    
    var body: some View {
            ZStack {
                Background()
                PreviewLayer()
                ControlsLayer()
                OverlayLayer()
            }
            .navigationBarHidden(true)
            .onAppear(perform: onAppear)
            .onDisappear(perform: onDisappear)
            .onReceive(routingUpdate, perform: { routingState = $0 })
            .sheet(isPresented: routingBinding.predictionDetailsSheet, content: { predictionDetailsView() })
            .sheet(isPresented: routingBinding.allPredictionsListSheet, content: { allPredictionsListView() })
            .sheet(isPresented: routingBinding.lowPowerModeSheet, content: { lowPowerModeInfo() })
            .sheet(isPresented: routingBinding.imagePickerSheet, content: { imagePickerView() })
            .allowsHitTesting(!viewModel.shouldFreezeButtons)
            .loader(isPresented: $viewModel.isLoaderPresented)
    }
}

// MARK: - View builders
extension CameraView {
    // MARK: Layers
    @ViewBuilder
    private func Background() -> some View {
        Theme.Color.black.color.ignoresSafeArea()
    }
    
    @ViewBuilder
    private func PreviewLayer() -> some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                    .frame(minHeight: 0)
                ImageContent(geometry: geometry)
            }.onChange(of: geometry.size, perform: onCanvasSizeChange)
            .onChange(of: viewModel.mode, perform: onViewModeChange)
        }
    }
    
    @ViewBuilder
    private func ControlsLayer() -> some View {
        #if CONTROLLESS
        EmptyView()
        #else
        GeometryReader { geometry in
            VStack(spacing: 0) {
                    OptionBar()
                        .padding(.horizontal, 10)
                        .frame(height: getOptionBarHeight(for: geometry.size))
                        .background(Theme.Color.black.color.opacity(0.3))
                        .transition(optionBarAnimation)
                Spacer()
                    .showStatus(configuration.statusPublisher, statusBag: configuration.statusBag)
                MainCameraControls()
                    .transition(mainCameraControlButtonsAnimation)
                    .padding(.bottom, 30)
            }
        }
        #endif
    }
    
    @ViewBuilder
    private func OverlayLayer() -> some View {
        VStack {
            Spacer()
            PreviewSettingsSheet()
        }
    }
    
    // MARK: Content
    @ViewBuilder
    private func ImageContent(geometry: GeometryProxy) -> some View {
        switch viewModel.mode {
        case .live:
            LiveView(geometry: geometry)
                .inject(injected)
                .frame(width: geometry.size.width, height: geometry.size.width * AppDefaults.previewAspectRatio, alignment: .center)
                .gesture(magnificationGesture)
                .overlay(ShutterView())
        case .captured, .picked:
            ZoomableImagePreview(
                previewSettings: detectionPreviewSettings,
                size: getCanvasSize(for: geometry.size),
                previewedImage: viewModel.currentImage,
                onAnnotationTap: showPredictionDetailsView(prediction:)
            ).inject(injected)
            .frame(width: geometry.size.width, height: geometry.size.width * AppDefaults.previewAspectRatio, alignment: .center)
        case .noPermission:
            PermissionView(
                currentPermissionStatus: injected.appState[\.permissions.cameraAccess],
                askForPermissionAction: askForCameraPermission,
                pickImageAction: showImagePicker,
                openSettingsAction: openAppSettings
            ).frame(width: geometry.size.width, height: geometry.size.width * AppDefaults.previewAspectRatio, alignment: .center)
        case .empty:
            Theme.Color.black.color
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    // MARK: Button setup
    @ViewBuilder
    private func OptionBar() -> some View {
        switch viewModel.mode {
        case .captured, .picked:
            HStack(alignment: .center) {
                CameraOptionsBar.ButtonView(
                    tapAction: .action { withAnimation { enterPrimaryMode() } },
                    content: .image(image: Theme.Image.chevronLeft, scale: 0.9)
                )
                Spacer(minLength: 0)
                CameraOptionsBar.ButtonView(
                    tapAction: .action(!currentDetections.isEmpty ? showAllPredictionsList : nil),
                    content: .text(text: Text(viewModel.detectionDescription))
                )
                Spacer()
                Group {
                    NavigationLink(isActive: $viewModel.isSettingsScreenPresented, destination: {
                        SettingsView()
                            .inject(injected)
                            .environment(\.modalMode, $viewModel.isSettingsScreenPresented)
                    }) { EmptyView() }
                    CameraOptionsBar.ButtonView(
                        tapAction: .action { viewModel.isSettingsScreenPresented = true },
                        content: .image(image: Theme.Image.more)
                    )
                }
            }
        case .live, .noPermission, .empty:
            HStack(alignment: .center) {
                CameraOptionsBar.ButtonView(
                    tapAction: .action { viewModel.isFlashEnabled.toggle() },
                    content: .strikethroughImage(
                        image: Theme.Image.bolt,
                        strikethroughScale: 0.6,
                        isStrikethroughDisplayed: !viewModel.isFlashEnabled
                    )
                ).disabled(viewModel.mode != .live)
                Spacer()
                CameraOptionsBar.ButtonView(
                    tapAction: .action { switchState(of: .liveDetection) },
                    content: .strikethroughImage(
                        image: Theme.Image.viewfinder,
                        scale: 0.9,
                        strikethroughScale: 1.1,
                        isStrikethroughDisplayed: !viewModel.isLiveDetecitonEnabled,
                        weight: .semibold
                    )
                ).disabled(viewModel.mode != .live)
                Spacer()
                CameraOptionsBar.ButtonView(
                    tapAction: .action { switchState(of: .showPreviewSettings) },
                    content: .strikethroughImage(
                        image: Theme.Image.eye,
                        strikethroughScale: 0.7,
                        isStrikethroughDisplayed: !viewModel.areDetectionsVisible
                    )
                ).disabled(viewModel.mode != .live)
                Spacer()
                Group {
                    NavigationLink(isActive: $viewModel.isSettingsScreenPresented, destination: {
                        SettingsView()
                            .inject(injected)
                            .environment(\.modalMode, $viewModel.isSettingsScreenPresented)
                    }) { EmptyView() }
                    CameraOptionsBar.ButtonView(
                        tapAction: .action { viewModel.isSettingsScreenPresented = true },
                        content: .image(image: Theme.Image.more)
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func MainCameraControls() -> some View {
        switch viewModel.mode {
        case .captured, .picked:
            HStack(alignment: .center) {
                Spacer()
                CameraMainControls.ButtonView(
                    mode: .imageOption(Theme.Image.list),
                    tapAction: .action(showAllPredictionsList)
                ).disabled(currentDetections.isEmpty)
                Spacer()
                CameraMainControls.ButtonView(
                    mode: .imageOption(viewModel.areDetectionsVisible ? Theme.Image.eye : Theme.Image.slashedEye),
                    tapAction: .action { switchState(of: .showPreviewSettings) }
                ).disabled(currentDetections.isEmpty)
                Spacer()
                CameraMainControls.ButtonView(
                    mode: .imageOption(Theme.Image.save),
                    tapAction: .action(saveImage)
                )
                Spacer()
            }.modifier(CameraMainControls())
        case .live:
            HStack(alignment: .center) {
                Spacer()
                CameraMainControls.ButtonView(
                    mode: .imageOption(Theme.Image.pictures),
                    tapAction: .action(showImagePicker)
                )
                Spacer()
                CameraMainControls.ButtonView(
                    mode: .shutter,
                    tapAction: .action(takePhoto)
                )
                Spacer()
                CameraMainControls.ButtonView(
                    mode: .zoom(viewModel.presentedZoomValue),
                    tapAction: .action { injected.interactors.cameraInteractor.switchCamera() }
                )
                Spacer()
            }.modifier(CameraMainControls())
        case .empty, .noPermission:
            EmptyView()
        }
    }
    
    // MARK: Additional Views
    @ViewBuilder
    private func PreviewSettingsSheet() -> some View {
        if viewModel.areDetectionPreviewSettingsDisplayed {
            OverlaySheet(isPresented: $viewModel.areDetectionPreviewSettingsDisplayed) {
                DetectionPreviewSettingsView(
                    settings: detectionPreviewSettings,
                    isLiveDetectionEnabled: viewModel.mode == .live ? $viewModel.isLiveDetecitonEnabled : .constant(true)
                )
            }.colorScheme(.dark)
        }
    }
    
    @ViewBuilder
    private func LiveView(geometry: GeometryProxy) -> some View {
        #if PREVIEW
        VideoPreview(
            shouldDisplayObservations: $viewModel.shouldDisplayObservations,
            previewSettings: detectionPreviewSettings,
            predictionsPublisher: configuration.observationPublisher.eraseToAnyPublisher(),
            size: getCanvasSize(for: geometry.size),
            onAnnotationTap: showPredictionDetailsView(prediction:),
            onFrameBufferUpdate: { buffer in
                detect(in: buffer, size: configuration.canvasSize, orientation: .portarait)
            }
        )
        #if BENCHMARK
        .overlay(FPSInfo())
        #endif
        #else
        CameraPreview(
            shouldDisplayObservations: $viewModel.shouldDisplayObservations,
            previewSettings: detectionPreviewSettings,
            predictionsPublisher: configuration.observationPublisher.eraseToAnyPublisher(),
            size: getCanvasSize(for: geometry.size),
            session: configuration.session,
            onAnnotationTap: showPredictionDetailsView(prediction:)
        )
        #endif
    }
    
    @ViewBuilder
    private func ShutterView() -> some View {
        if viewModel.isShutterOverlayDisplayed {
            Theme.Color.black.color
        }
    }
    
    #if BENCHMARK
    @ViewBuilder
    private func FPSInfo() -> some View {
        VStack(alignment: .center) {
            VStack(alignment: .center, spacing: 10) {
                HStack {
                    Text("Device:")
                        .font(.system(size: 18, weight: .regular))
                    Text(UIDevice.current.type.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                }.foregroundColor(Theme.Color.white.color)
                Text("\(String(format: "%.3f", viewModel.fps)) fps")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Theme.Color.white.color)
            }.padding(20)
            .background(Theme.Color.darkGray.color.opacity(0.7).cornerRadius(20))
            Spacer()
        }.padding(30)
    }
    #endif
    
    // MARK: Animations
    private var optionBarAnimation: AnyTransition { .opacity }
    
    private var notificationAnimation: AnyTransition { .move(edge: .top).combined(with: .opacity) }
    
    private var mainCameraControlButtonsAnimation: AnyTransition {
        switch viewModel.mode {
        case .captured, .picked:
            return .asymmetric (
                insertion:
                    .move(edge: .bottom)
                    .combined(with: .opacity)
                    .combined(with: .scale(scale: 0.75)),
                removal:
                    .move(edge: .bottom)
                    .combined(with: .opacity)
                    .combined(with: .scale(scale: 1.5))
            )
        case .live:
            return .asymmetric(
                insertion:
                    .move(edge: .bottom)
                    .combined(with: .opacity)
                    .combined(with: .scale(scale: 1.5)),
                removal:
                    .move(edge: .bottom)
                    .combined(with: .opacity)
                    .combined(with: .scale(scale: 0.75))
            )
        case .empty, .noPermission:
            return .identity
        }
    }
    
    // MARK: Gestures
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { magnitude in
                setZoom(gestureMagnitude: magnitude)
            }
            .onEnded { _ in
                configuration.zoomState.oldMagnitude = 1.0
                configuration.zoomState.initialZoomValue = nil
            }
    }
}

// MARK: - View state handlers
extension CameraView {
    private func onCanvasSizeChange(_ newValue: CGSize) {
        configuration.canvasSize = getCanvasSize(for: newValue)
    }
    
    private func onViewModeChange(_ newValue: PreviewMode) {
        switch newValue {
        case .live:
            didEnterLiveMode()
        case .captured, .picked:
            didEnterCapturedMode()
        case .empty:
            didEnterEmptyMode()
        case .noPermission: break
        }
    }
    
    private func onFramesUpdate(_ newValue: Double) {
        viewModel.fps = newValue
    }
    
    private func setupStatusBar(to mode: UIStatusBarStyle) {
        UIApplication.setStatusBarStyle(mode)
    }
    
    private func didEnterCapturedMode() {
        injected.interactors.cameraInteractor.stop()
            .sink(receiveCompletion: { _ in }, receiveValue: {})
            .store(in: cancelBag)
    }
    
    private func didEnterEmptyMode() {
        injected.interactors.cameraInteractor.stop()
            .sink(receiveCompletion: { _ in }, receiveValue: {})
            .store(in: cancelBag)
    }
    
    private func didEnterLiveMode() {
        injected.interactors.cameraInteractor.start()
            .sink(receiveCompletion: { _ in }, receiveValue: {
                toggleTorch(to: viewModel.isFlashEnabled, silently: true)
            }).store(in: cancelBag)
    }
}

// MARK: - Publishers
extension CameraView {
    private var lowBatteryModeUpdates: AnyPublisher<Bool?, Never> {
        injected.appState.updates(for: \.system.isLowBatteryModeEnabled)
    }
    
    private var cameraPermissionUpdates: AnyPublisher<Permission.Status, Never> {
        injected.appState.updates(for: \.permissions.cameraAccess)
    }
    
    private var libraryPermisionUpdates: AnyPublisher<Permission.Status, Never> {
        injected.appState.updates(for: \.permissions.photoLibaryAccess)
    }
    
    private var imageUpdates: AnyPublisher<CVPixelBuffer, Never> {
        injected.interactors.cameraInteractor.imageOutputPublisher
    }
    
    #if BENCHMARK
    private var framesUpdates: AnyPublisher<Double, Never> {
        injected.interactors.detectorInteractor.fpsPublisher
    }
    #endif
    
    private var predictionsPublisher: AnyPublisher<[Observation], Never> {
        injected.interactors.detectorInteractor.predictionsPublisher
    }
    
    var routingUpdate: AnyPublisher<Routing, Never> {
        injected.appState.updates(for: \.routing.cameraView)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private var sheetDisplayedUpdates: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest4(
            injected.appState.updates(for: \.routing.cameraView.predictionDetailsSheet),
            injected.appState.updates(for: \.routing.cameraView.allPredictionsListSheet),
            injected.appState.updates(for: \.routing.cameraView.imagePickerSheet),
            injected.appState.updates(for: \.routing.cameraView.lowPowerModeSheet)
        ).map { $0.0 || $0.1 || $0.2 || $0.3 }
        .eraseToAnyPublisher()
    }
    
    private var otherSeceneDisplayedUpdates: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(sheetDisplayedUpdates, viewModel.$isSettingsScreenPresented)
            .map { $0.0 || $0.1 }
            .eraseToAnyPublisher()
    }
}

// MARK: - Interactions
extension CameraView {
    private func setZoom(gestureMagnitude: CGFloat) {
        let currentZoomRange = configuration.zoomState.zoomRange
        let oldValue = configuration.zoomState.oldZoomValue
        if configuration.zoomState.initialZoomValue == nil {
            configuration.zoomState.initialZoomValue = oldValue
        }
        let initialZoomValue = configuration.zoomState.initialZoomValue ?? oldValue
        
        let newValue = oldValue + (gestureMagnitude - configuration.zoomState.oldMagnitude) * initialZoomValue
        let normalizedValue = min(max(newValue, currentZoomRange.lowerBound), currentZoomRange.upperBound)
        guard normalizedValue != currentZoomRange.lowerBound || normalizedValue != oldValue,
              normalizedValue != currentZoomRange.upperBound || normalizedValue != oldValue
        else { return }
        
        configuration.zoomState.oldMagnitude = gestureMagnitude
        configuration.zoomState.oldZoomValue = normalizedValue
        injected.interactors.cameraInteractor.zoom(to: normalizedValue)
    }
    
    private func detect(in buffer: CVPixelBuffer, size: CGSize, orientation: OutputOrientation, cancelIfPending: Bool = true) {
        guard viewModel.isLiveDetecitonEnabled, viewModel.shouldAllowDetection, (!configuration.isCurrentlyDetecting || !cancelIfPending) else { return }
        let detectionFrame = CGRect(size: size)
        
        injected.interactors.detectorInteractor.detect(pixelBuffer: buffer, in: detectionFrame, orientation: orientation)
            .handleEvents(
                receiveSubscription: { _ in enterDetectingProcess() },
                receiveCompletion: { _ in escapeDetectingProcess() } ,
                receiveCancel: { escapeDetectingProcess() }
            ).sink(receiveCompletion: { _ in }, receiveValue: { observations in
                self.configuration.observationPublisher.send(observations)
            }).store(in: cancelBag)
    }
    
    private func configureCamera() {
        injected.interactors.cameraInteractor.configure(session: configuration.session)
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                    let notification = NotificationModel(type: .failure, message: "CameraSonfigurationFailureMessage".localized)
                    self.showNotification(notification)
                }
            }, receiveValue: { setup in
                configuration.zoomState.zoomRange = setup.zoomRange
            })
            .store(in: cancelBag)
    }
    
    private func saveImage() {
        guard let preview = viewModel.currentImage, let image = preview.image else {
            let notification = NotificationModel(type: .failure, message: ImageProcessingError.saveError.notificationMessage)
            showNotification(notification)
            return
        }
        let size = image.size.normalize(by: configuration.canvasSize)
        let detections = preview.detections ?? []
        let previewSettings = detectionPreviewSettings
        viewModel.isLoaderPresented = true
        
        injected.interactors.permissionInteractor.request(for: .photoLibraryAccess)
            .tryMap { permission -> Void in
                guard permission.isAccesable else { throw ImageProcessingError.libraryAccessNotAuthorized }
                return
            }.mapError { error -> ImageProcessingError in
                error as? ImageProcessingError ?? ImageProcessingError.saveError
            }.flatMap { _ in
                injected.interactors.detectorRendererInteractor.render(observations: detections, over: image, canvasSize: size, with: previewSettings)
            }.flatMap { image in
                injected.interactors.imageProcessingInteractor.save(image: image)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                viewModel.isLoaderPresented = false
                switch completion {
                case .failure(let error):
                    let notification = NotificationModel(type: .failure, message: error.notificationMessage)
                    showNotification(notification)
                case .finished:
                    let notification = NotificationModel(type: .success, message: "ImageSavedSuccessMessage".localized)
                    showNotification(notification)
                }
            }, receiveValue: { _ in })
            .store(in: cancelBag)
    }
    
    private func triggerShutterEffectWithLoader() -> AnyCancellable {
        Future { promise in
            viewModel.shouldFreezeButtons = true
            viewModel.isShutterOverlayDisplayed = true
            return promise(.success(()))
        }.delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .flatMap {
            Future { promise in
                viewModel.isShutterOverlayDisplayed = false
                return promise(.success(()))
            }
        }.delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
        .flatMap {
            Future { _ in
                viewModel.isLoaderPresented = true
            }
        }.handleEvents(receiveCancel: {
            viewModel.shouldFreezeButtons = false
            viewModel.isShutterOverlayDisplayed = false
            viewModel.isLoaderPresented = false
        }).sink { }
    }
    
    private func processPickedImage(imageData: ImageData) {
        let displayedImageSize = imageData.image?.size.normalize(by: configuration.canvasSize)
        processPickedImage(image: imageData, displayedImageSize: displayedImageSize, orientation: .portarait)
    }
    
    private func processPickedImage(image: ImageData, displayedImageSize: CGSize?, orientation: OutputOrientation) {
        enterDetectingProcess()
        viewModel.shouldAllowDetection = false
        Just(image.buffer)
            .setFailureType(to: Error.self)
            .unwrap(orThrow: CameraRunError.notConfigured)
            .mapError { _ in
                DetectorError.inputFailure
            }.flatMap { buffer -> AnyPublisher<[Observation], DetectorError> in
                guard let size = displayedImageSize else {
                    return Fail(error: .detectionFailure).eraseToAnyPublisher()
                }
                let bounds = CGRect(size: size)
                return injected.interactors.detectorInteractor.detect(pixelBuffer: buffer, in: bounds, orientation: orientation).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                escapeDetectingProcess()
                if case .failure(_) = completion {
                    let notification = NotificationModel(type: .failure, message: "ImageProcessingFailureMessage".localized)
                    showNotification(notification)
                }
            }, receiveValue: { observations in
                escapeDetectingProcess()
                viewModel.currentImage = PreviewedImage(image: image.image, detections: observations)
                viewModel.detectionDescription = getDetectionSummary(for: observations)
                withAnimation { enterCapturedMode() }
            }).store(in: cancelBag)
    }
    
    private func process(image: ImageData, orientation: OutputOrientation) -> AnyPublisher<PreviewedImage, DetectorError> {
        Just(image.buffer)
            .setFailureType(to: DetectorError.self)
            .unwrap(orThrow: DetectorError.detectionFailure)
            .map { buffer in
                buffer.rotate(to: orientation)
            }.unwrap(orThrow: DetectorError.detectionFailure)
            .mapError { _ in
                DetectorError.inputFailure
            }.flatMap { buffer -> AnyPublisher<[Observation], DetectorError> in
                guard let size = image.size?.normalize(by: configuration.canvasSize) else {
                    return Fail(error: .detectionFailure).eraseToAnyPublisher()
                }
                return injected.interactors.detectorInteractor.detect(pixelBuffer: buffer, in: CGRect(size: size), orientation: orientation).eraseToAnyPublisher()
            }.map { observations in
                PreviewedImage(image: image.image, detections: observations)
            }.eraseToAnyPublisher()
    }
    
    private func takePhoto() {
        let shutterAndLoader = triggerShutterEffectWithLoader()
        let orientation = configuration.orientation
        enterDetectingProcess()
        injected.interactors.cameraInteractor.takePhoto(withFlash: viewModel.isFlashEnabled)
            .mapError { _ in
                DetectorError.inputFailure
            }
            .receive(on: DispatchQueue.main)
            .flatMap { photoData in
                enterCapturedMode(photoData: photoData)
            }.flatMap { image in
                process(image: image, orientation: orientation)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                escapeDetectingProcess()
                shutterAndLoader.cancel()
                if case .failure(let error) = completion {
                    var message: String = "GlobalUnknownError".localized
                    switch error {
                    case .modelNotConfigured, .detectionFailure:
                        message = "ImageProcessingFailureMessage".localized
                    case .inputFailure:
                        message = "ImageTakeFailureMessage".localized
                    }
                    let notification = NotificationModel(type: .failure, message: message)
                    self.showNotification(notification)
                }
            }, receiveValue: { image in
                viewModel.detectionDescription = getDetectionSummary(for: image.detections ?? [])
                viewModel.currentImage = image
            }).store(in: cancelBag)
    }
    
    private func enterCapturedMode(photoData: PhotoData) -> AnyPublisher<PhotoData, DetectorError> {
        Future { promise in
            guard let image = photoData.image else {
                return promise(.failure(.inputFailure))
            }
            viewModel.detectionDescription = "CameraProcessingState".localized
            viewModel.currentImage = PreviewedImage(image: image, detections: [])
            withAnimation { enterCapturedMode() }
            return promise(.success(photoData))
        }.eraseToAnyPublisher()
    }
    
    private func toggleTorch(to newValue: Bool, silently: Bool = false) {
        injected.interactors.cameraInteractor.toggleTorch(to: newValue)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                guard !silently else { return }
                if case .failure(_) = completion {
                    let notification = NotificationModel(type: .failure, message: "FlashTriggerFailureMessage".localized)
                    showNotification(notification)
                }
            }, receiveValue: {
                guard !silently else { return }
                guard let message = SwitchedOperation.flash.description(forValue: newValue) else { return }
                let statusModel = StatusModel(message: message)
                showStatusChange(statusModel)
            })
            .store(in: cancelBag)
    }
    
    private func askForCameraPermission() {
        injected.interactors.permissionInteractor.request(for: .cameraAccess)
            .sink { _ in
                withAnimation { enterPrimaryMode() }
            }.store(in: cancelBag)
    }
    
    private func openAppSettings() {
        injected.interactors.systemEventsInteractor.openAppSettings()
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                    let notification = NotificationModel(
                        type: .failure,
                        message: "SystemSettingsOpenFailureMessage".localized
                    )
                    showNotification(notification)
                }
            }, receiveValue: { })
            .store(in: cancelBag)
    }
}

// MARK: - Setup
extension CameraView {
    private func setupView() {
        guard !configuration.isConfigured else { return }
        configuration.isConfigured = true
        
        setupVision()
        setupImagePicker()
        
        setupCameraFlashPipeline()
        setupCameraFramePipeline()
        setupLowPowerModePipeline()
        setupStatusBarStylePipeline()
        setupCameraZoomValuePipeline()
        setupCameraPermissionPipeline()
        setupDetectionEnabledPipeline()
        setupDeviceOrientationPipeline()
        setupDetectionSettingsValidation()
        setupDetectionObservationsPipeline()
        
        setupViewMode()
        
        #if BENCHMARK
        setupFrameRatePipeline()
        #endif
    }
    
    private func onAppear() {
        setupView()
        setupViewModelFromSavedState()
        guard viewModel.mode == .live else { return }
        startCamera()
    }
    
    private func onDisappear() {
        toggleTorch(to: false, silently: true)
        injected.interactors.cameraInteractor.stop()
            .sink(receiveCompletion: { _ in }, receiveValue: {})
            .store(in: cancelBag)
    }
    
    private func startCamera() {
        otherSeceneDisplayedUpdates
            .filter { !$0 }
            .first()
            .flatMap { _ in
                injected.interactors.cameraInteractor.start()
            }.sink(receiveCompletion: { _ in }, receiveValue: {
                toggleTorch(to: viewModel.isFlashEnabled, silently: true)
            }).store(in: cancelBag)
    }
    
    private func setupViewMode() {
        injected.interactors.permissionInteractor.resolveStatus(for: .cameraAccess)
            .receive(on: DispatchQueue.main)
            .sink { permissionStatus in
                withAnimation { enterPrimaryMode() }
            }.store(in: cancelBag)
    }
    
    private func setupVision() {
        injected.interactors.detectorInteractor.setupVision()
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                    let notification = NotificationModel(type: .failure, message: "DetectorSetupFailureMessage".localized)
                    showNotification(notification)
                }
            }, receiveValue: { _ in })
            .store(in: cancelBag)
    }
    
    private func setupCameraFramePipeline() {
        injected.interactors.cameraInteractor.imageOutputPublisher
            .sink { buffer in
                detect(in: buffer, size: configuration.canvasSize, orientation: configuration.orientation)
            }.store(in: cancelBag)
    }
    
    private func setupCameraPermissionPipeline() {
        injected.appState.updates(for: \.permissions.cameraAccess)
            .removeDuplicates()
            .filter(\.isAccesable)
            .map(\.isAccesable)
            .first()
            .sink(receiveValue: { _ in
                configureCamera()
            }).store(in: cancelBag)
    }
    
    private func setupCameraZoomValuePipeline() {
        injected.interactors.cameraInteractor.cameraZoomPublisher
            .compactMap { Double(exactly: $0) }
            .map { ($0 * 10).rounded() / 10 }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { value in
                viewModel.presentedZoomValue = value
            }.store(in: cancelBag)
        
        injected.interactors.cameraInteractor.cameraZoomPublisher
            .removeDuplicates()
            .sink { value in
                configuration.zoomState.oldZoomValue = value
            }.store(in: cancelBag)
    }
    
    private func setupCameraFlashPipeline() {
        viewModel.$isFlashEnabled
            .dropFirst()
            .sink(receiveValue: { value in
                toggleTorch(to: value)
            }).store(in: cancelBag)
    }
    
    private func setupDetectionEnabledPipeline() {
        sheetDisplayedUpdates
            .sink { isAnySheetDisplayed in
                if !isAnySheetDisplayed && viewModel.mode == .live {
                    toggleTorch(to: viewModel.isFlashEnabled, silently: true)
                } else {
                    toggleTorch(to: false, silently: true)
                }
                viewModel.shouldAllowDetection = !isAnySheetDisplayed
            }.store(in: cancelBag)
    }
    
    private func setupDetectionSettingsValidation() {
        Publishers.CombineLatest(detectionPreviewSettings.$isAnnotationEnabled, detectionPreviewSettings.$isDetectionFrameEnabled)
            .map { $0 || $1 }
            .sink { value in
                withAnimation { viewModel.areDetectionsVisible = value }
            }.store(in: cancelBag)
    }
    
    private func setupDetectionObservationsPipeline() {
        Publishers.CombineLatest(viewModel.$isLiveDetecitonEnabled, viewModel.$shouldAllowDetection)
            .map { $0 && $1 }
            .sink { value in
                viewModel.shouldDisplayObservations = value
            }.store(in: cancelBag)
    }
    
    private func setupStatusBarStylePipeline() {
        viewModel.$isSettingsScreenPresented
            .sink { isSettingsScreenPresented in
                if isSettingsScreenPresented {
                    setupStatusBar(to: .default)
                } else {
                    setupStatusBar(to: .lightContent)
                }
            }.store(in: cancelBag)
    }
    
    private func setupLowPowerModePipeline() {
        let lowBatteryModePublisher = injected.appState.updates(for: \.system.isLowBatteryModeEnabled)
            .compactMap { $0 }
            .removeDuplicates()
        let liveModePublisher = viewModel.$mode
            .map { $0 == .live }
            .removeDuplicates()
        let liveDetectionPublisher = viewModel.$isLiveDetecitonEnabled
            .removeDuplicates()
        Publishers.CombineLatest3(lowBatteryModePublisher, liveModePublisher, liveDetectionPublisher)
            .filter { $0.0 && $0.1 && $0.2 && !configuration.didDisplayLowPowerModeInfo }
            .sink { _ in
                showLowPowerModeInfo()
            }.store(in: cancelBag)
    }
    
    private func setupDeviceOrientationPipeline() {
        injected.appState.updates(for: \.system.deviceOrientation)
            .compactMap { orientation in
                OutputOrientation(from: orientation)
            }.removeDuplicates()
            .sink(receiveValue: { orientation in
                injected.interactors.cameraInteractor.setOutputOrientation(to: orientation)
                configuration.orientation = orientation
            }).store(in: cancelBag)
    }
    
    #if BENCHMARK
    private func setupFrameRatePipeline() {
        framesUpdates
            .receive(on: DispatchQueue.main)
            .assign(to: \.fps, on: viewModel)
            .store(in: cancelBag)
    }
    #endif
    
    private func setupViewModelFromSavedState() {
        viewModel.isLiveDetecitonEnabled = injected.appState[\.savedState.liveDetection]
        detectionPreviewSettings.isAnnotationEnabled = injected.appState[\.savedState.showAnnotationLabel]
        detectionPreviewSettings.isDetectionFrameEnabled = injected.appState[\.savedState.showAnnotationFrame]
        detectionPreviewSettings.annotationSize = CGFloat(injected.appState[\.savedState.annotationLabelSize])
        detectionPreviewSettings.detectionFrameColor = Color(UIColor(hexString: injected.appState[\.savedState.annotationFrameColor]) ?? AppDefaults.annotationFrameColor)
    }
    
    private func setupImagePicker() {
        configuration.imagePicker.onImagePickedAction = processPickedImage(imageData:)
    }
}

// MARK: - Helpers
extension CameraView {
    private var routingBinding: Binding<Routing> {
        $routingState.dispatched(to: injected.appState, \.routing.cameraView)
    }
    
    private var selectedClassInfo: DetectionClassInfo? {
        guard
            let selection = viewModel.selectedPrediction,
            let topItem = selection.topObservation
        else { return nil }
        
        let classInfo = injected.appState[\.detectorData.classInfo]
        guard topItem.classIndex >= 0 && topItem.classIndex < classInfo.count else { return nil }
        return classInfo[topItem.classIndex]
    }
    
    private var selectedAccuracy: Double? {
        guard
            let selection = viewModel.selectedPrediction,
            let topItem = selection.topObservation
        else { return nil }
        return Double(topItem.score)
    }
    
    private var currentDetections: [Observation] {
        viewModel.currentImage?.detections ?? []
    }
    
    private func getDetectionSummary(for detections: [Observation]) -> String {
        guard !detections.isEmpty else {
            return "CameraDetectionNotFound".localized
        }
        return "CameraDetectionObjectAmountMessage".localized(detections.count)
    }
    
    private func getCanvasSize(for size: CGSize) -> CGSize {
        CGSize(width: size.width, height: size.width * AppDefaults.previewAspectRatio)
    }
    
    private func getOptionBarHeight(for size: CGSize) -> CGFloat {
        max(size.height - configuration.canvasSize.height, 60)
    }
    
    private func switchState(of operation: SwitchedOperation, silently: Bool = false) {
        let oldValue = viewModel[keyPath: operation.path]
        let newValue = !oldValue
        setState(of: operation, to: newValue, silently: silently)
    }
    
    private func setState(of operation: SwitchedOperation, to newValue: Bool, silently: Bool = false) {
        withAnimation { viewModel[keyPath: operation.path] = newValue }
        updateSavedState(for: operation.savedStatePath, to: newValue)
        guard let description = operation.description(forValue: newValue), !silently else { return }
        let status = StatusModel(message: description)
        showStatusChange(status)
    }
    
    private func updateSavedState<T: Equatable>(for path: ReferenceWritableKeyPath<AppState,T>?, to newValue: T) {
        guard let path = path else { return }
        injected.appState[path] = newValue
    }
    
    private func showNotification(_ notification: NotificationModel) {
        injected.interactors.userInterfaceInteractor.showNotification(notification, with: notificationPublisher)
    }
    
    private func showStatusChange(_ status: StatusModel) {
        configuration.statusPublisher.send(status)
    }
    
    private func enterCapturedMode() {
        enter(mode: .captured)
    }
    
    private func enterPickedMode() {
        enter(mode: .picked)
    }
    
    private func enterLiveMode() {
        enter(mode: .live)
    }
    
    private func enterPrimaryMode() {
        let cameraPermissionStatus = injected.appState[\.permissions.cameraAccess]
        if cameraPermissionStatus.isAccesable {
            enter(mode: .live)
        } else {
            enter(mode: .noPermission)
        }
    }
    
    private func enter(mode: PreviewMode) {
        viewModel.areDetectionPreviewSettingsDisplayed = false
        viewModel.mode = mode
    }
    
    private func enterDetectingProcess() {
        configuration.isCurrentlyDetecting = true
    }
    
    private func escapeDetectingProcess() {
        configuration.isCurrentlyDetecting = false
    }
}

// MARK: - Routing
extension CameraView {
    // MARK: Detection details
    private func showPredictionDetailsView(prediction: Observation) {
        viewModel.selectedPrediction = prediction
        injected.appState[\.routing.cameraView.predictionDetailsSheet] = true
    }
    
    private func predictionDetailsView() -> some View {
        NavigationScene {
            DetectionDetails(singleObservation: viewModel.selectedPrediction)
                .inject(injected)
                .environment(\.modalMode, routingBinding.predictionDetailsSheet)
        }
    }
    
    // MARK: All detections
    private func showAllPredictionsList() {
        injected.appState[\.routing.cameraView.allPredictionsListSheet] = true
    }
    
    private func allPredictionsListView() -> some View {
        NavigationScene {
            DetectionDetails(allObservations: currentDetections)
                .inject(injected)
                .environment(\.modalMode, routingBinding.allPredictionsListSheet)
        }
    }
    
    // MARK: Low power mode info
    private func showLowPowerModeInfo() {
        configuration.didDisplayLowPowerModeInfo = true
        injected.appState[\.routing.cameraView.lowPowerModeSheet] = true
    }
    
    private func lowPowerModeInfo() -> some View {
        NavigationScene {
            LowPowerModeInfoView(isLiveDetectionEnabled: $viewModel.isLiveDetecitonEnabled)
                .inject(injected)
                .environment(\.modalMode, routingBinding.lowPowerModeSheet)
        }
    }
    
    // MARK: Image picker
    private func showImagePicker() {
        injected.appState[\.routing.cameraView.imagePickerSheet] = true
    }
    
    private func imagePickerView() -> some View {
        configuration.imagePicker
    }
}
