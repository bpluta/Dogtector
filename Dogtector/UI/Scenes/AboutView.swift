//
//  AboutView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

struct AboutView: View {
    @Environment(\.notificationPublisher) private var notificationPublisher: NotificationSubject
    @Environment(\.injected) private var injected: DependencyContainer
    @Environment(\.modalMode) private var modalMode
    
    private var cancelBag = CancelBag()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 5) {
                ApplicationInfo()
                Description()
                    .padding(20)
                Actions()
                Dedication()
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                Footer()
                    .padding(.vertical, 10)
            }.padding(.bottom, 20)
        }.navigationWithCloseButton()
    }
    
    @ViewBuilder
    private func ApplicationInfo() -> some View {
        HStack(spacing: 10) {
            Theme.Image.appIcon
                .resizable()
                .scaledToFit()
                .frame(width: 100)
            VStack(spacing: 0) {
                AppNameText(AppDefaults.appName)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .foregroundColor(Theme.Color.clear.color)
                    .overlay(
                        AppNameGradient()
                            .mask(AppNameText(AppDefaults.appName))
                    ).frame(width: 150)
                Text("AboutVersionDescription".localized(appVersion).uppercased())
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Color.gray.color)
            }
        }.padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func Description() -> some View {
        Text("AboutDescription".localized)
            .multilineTextAlignment(.center)
            .font(.system(size: 14))
            .foregroundColor(Theme.Color.gray.color)
            .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func AppNameText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 30, weight: .bold))
            .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    private func Section(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(Theme.Color.gray.color)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder func Actions() -> some View {
        Group {
            NavigationLink(destination: {
                TipJarView()
                    .inject(injected)
                    .environment(\.modalMode, modalMode)
            }) {
                ChevronSettingsCell(
                    iconType: .donate,
                    title: "AboutSendDonationTitle".localized,
                    subtitle: nil
                )
            }
            Divider().background(Theme.Color.gray.color)
            NavigationLink(destination: {
                LicenceInfoView()
                    .inject(injected)
                    .environment(\.modalMode, modalMode)
            }) {
                ChevronSettingsCell(
                    iconType: .licence,
                    title: "AboutLicencesTitle".localized,
                    subtitle: nil
                )
            }
            Divider().background(Theme.Color.gray.color)
            Button(action: copyDebugData) {
                ChevronSettingsCell(
                    iconType: .debug,
                    title: "AboutCopyDebugData".localized,
                    subtitle: nil
                )
            }
        }.padding(.horizontal, 30)
    }
    
    @ViewBuilder
    private func Dedication() -> some View {
        HStack(spacing: 0) {
            Theme.Image.sammyDog
                .resizable()
                .scaledToFit()
                .frame(height: 70)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text("AboutDedicationInfoTitle".localized)
                    .font(.system(size: 16, weight: .semibold))
                Text("AboutDedicationInfoDescripton".localized)
                    .foregroundColor(Theme.Color.gray.color)
                    .font(.system(size: 14))
                    .fixedSize(horizontal: false, vertical: true)
            }.frame(width: 170)
            .padding(.horizontal, 10)
        }.padding(20)
        .background(
            Capsule().foregroundColor(Theme.Color.lightestAdaptiveGray.color)
        )
    }
    
    @ViewBuilder
    private func Footer() -> some View {
        Text("AboutAuthorCaption".localized)
            .multilineTextAlignment(.center)
            .foregroundColor(Theme.Color.gray.color)
            .font(.system(size: 14))
    }
    
    private func AppNameGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Theme.Color.primary.color,
                Theme.Color.primaryDarker.color,
            ]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
}

// MARK: - Helpers
extension AboutView {
    private func copyDebugData() {
        injected.interactors.systemEventsInteractor.copyDebugData()
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                    let notification = NotificationModel(
                        type: .failure,
                        message: "AboutDebugDataCopyFailureMessage".localized,
                        color: Theme.Color.listBackground.color
                    )
                    showNotification(notification)
                }
            }, receiveValue: {
                let notification = NotificationModel(
                    type: .success,
                    message: "AboutDebugDataCopySuccessMessage".localized,
                    color: Theme.Color.listBackground.color
                )
                showNotification(notification)
            }).store(in: cancelBag)
    }
    
    private func showNotification(_ notification: NotificationModel) {
        injected.interactors.userInterfaceInteractor.showNotification(notification, with: notificationPublisher)
    }

    private var appVersion: String {
        injected.interactors.systemEventsInteractor.getApplicationInfo()?.appVersion ?? "AboutUnknownSystemVersion".localized
    }
}

#if DEBUG
struct AboutViewPreview: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
#endif
