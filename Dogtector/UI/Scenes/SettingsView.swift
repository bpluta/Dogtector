//
//  SettingsView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

// MARK: - Models
extension SettingsView {
    class ViewModel: ObservableObject {
        @Published var isDetectionEnabled: Bool = false
        @Published var isRestoreAlertPresented: Bool = false
        @Published var isAboutSheetDisplayed: Bool = false
        @Published var isDonateSheetDisplayed: Bool = false
        @Published var isHelpSheetDisplayed: Bool = false
    }
    
    struct SectionData: Identifiable {
        let id = UUID()
        
        let name: String
        let cells: [SettingsCellData<AnyView>]
    }
}

// MARK: - View
struct SettingsView: View {
    @Environment(\.notificationPublisher) private var notificationPublisher: NotificationSubject
    @Environment(\.injected) private var injected: DependencyContainer
    @Environment(\.modalMode) private var modalMode
    
    @StateObject var viewModel = ViewModel()
    
    var cancelBag = CancelBag()
    
    var sections: [SectionData] {[
        SectionData(name: "SettingsPreferencesSectionTitle".localized, cells: [
            ToggleSettingsCellData(
                icon: .detection,
                title: "SettingsLiveDetectionSwitchTitle".localized,
                subtitle: "SettingsLiveDetectionSwitchDescription".localized,
                value: $viewModel.isDetectionEnabled
            )
        ]),
        SectionData(name: "SettingsMenuSectionTitle".localized, cells: [
            ChevronSettingsCellData(
                icon: .about,
                title: "SettingsAboutAppTitle".localized,
                action: .button(action: showAboutAppSheet)
            ),
            ChevronSettingsCellData(
                icon: .reset,
                title: "SettingsResetToDefaultsTitle".localized,
                action: .button(action: showRestoreSettingsAlert)
            ),
            ChevronSettingsCellData(
                icon: .share,
                title: "SettingsShareAppTitle".localized,
                action: .button(action: shareApp)
            ),
            ChevronSettingsCellData(
                icon: .donate,
                title: "SettingsDonationTitle".localized,
                action: .button(action: showDonateSheet)
            ),
            ChevronSettingsCellData(
                icon: .help,
                title: "SettingsHelpTitle".localized,
                action: .button(action: showHelpSheet)
            )
        ])
    ]}
    
    var body: some View {
        List {
            ForEach(sections, id: \.id) { section in
                Section(header: Text(section.name)) {
                    ForEach(section.cells, id: \.id) { cellData in
                        cellData.cell
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .alert(isPresented: $viewModel.isRestoreAlertPresented, content: RestoreSettingsAlert)
        .sheet(isPresented: $viewModel.isAboutSheetDisplayed, content: aboutApp)
        .sheet(isPresented: $viewModel.isDonateSheetDisplayed, content: donateScreen)
        .sheet(isPresented: $viewModel.isHelpSheetDisplayed, content: helpView)
        .navigationBarHidden(false)
        .navigationBarItems(leading: backButton())
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("SettingsTitle".localized, displayMode: .large)
        .onAppear(perform: setupLivePreviewPipeline)
    }
    
    private func RestoreSettingsAlert() -> Alert {
        Alert(
            title: Text("SettingsRestoreAlertTitle".localized),
            message: Text("SettingsRestoreAlertQuestion".localized),
            primaryButton: .destructive(Text("SettingsRestoreAlertProceedButtonTitle".localized), action: restoreSettings),
            secondaryButton: .cancel()
        )
    }
    
    @ViewBuilder
    private func backButton() -> some View {
        Button(action: dismiss) {
            HStack(spacing: 4) {
                Theme.Image.chevronLeft
                    .font(.title3.weight(.medium))
                Text("GlobalBack".localized)
                    .font(.body.weight(.regular))
            }.frame(height: 44)
        }
    }
    
    private func aboutApp() -> some View {
        NavigationScene {
            AboutView()
                .inject(injected)
                .environment(\.modalMode, $viewModel.isAboutSheetDisplayed)
        }
    }
    
    private func donateScreen() -> some View {
        NavigationScene {
            TipJarView()
                .inject(injected)
                .environment(\.modalMode, $viewModel.isDonateSheetDisplayed)
        }
    }
    
    private func helpView() -> some View {
        NavigationScene {
            HelpView()
                .inject(injected)
                .environment(\.modalMode, $viewModel.isHelpSheetDisplayed)
        }
    }
}

// MARK: - Helpers
extension SettingsView {
    private func showRestoreSettingsAlert() {
        viewModel.isRestoreAlertPresented = true
    }
    
    private func showAboutAppSheet() {
        viewModel.isAboutSheetDisplayed = true
    }
    
    private func showDonateSheet() {
        viewModel.isDonateSheetDisplayed = true
    }
    
    private func showHelpSheet() {
        viewModel.isHelpSheetDisplayed = true
    }
    
    private func dismiss() {
        modalMode.wrappedValue = false
    }
    
    private func restoreSettings() {
        injected.interactors.userSettingsInteractor.restoreToDefaults()
            .sink(receiveValue: {
                withAnimation { updateLiveDetection() }
                let notification = NotificationModel(
                    type: .success,
                    message: "SettingsRestoreSuccessMessage".localized
                )
                showNotification(notification)
            }).store(in: cancelBag)
    }
    
    private func shareApp() {
        injected.interactors.systemEventsInteractor.openShareApp()
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                    let notification = NotificationModel(
                        type: .failure,
                        message: "SettingsShareSheetErrorMessage".localized
                    )
                    showNotification(notification)
                }
            }, receiveValue: { })
            .store(in: cancelBag)
    }
    
    private func updateLiveDetection() {
        viewModel.isDetectionEnabled = injected.appState[\.savedState.liveDetection]
    }
    
    private func showNotification(_ notification: NotificationModel) {
        injected.interactors.userInterfaceInteractor.showNotification(notification, with: notificationPublisher)
    }
    
    private func setupLivePreviewPipeline() {
        updateLiveDetection()
        viewModel.$isDetectionEnabled
            .sink { newValue in
                injected.appState[\.savedState.liveDetection] = newValue
            }.store(in: cancelBag)
    }
}

#if DEBUG
struct SettingsViewPreview: PreviewProvider {
    @State static var isLiveDetectionEnabled: Bool = false
    
    static var previews: some View {
        SettingsView()
            .inject(DependencyContainer.preview)
    }
}
#endif
