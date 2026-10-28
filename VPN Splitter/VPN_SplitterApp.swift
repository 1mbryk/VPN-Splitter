//
//  VPN_SplitterApp.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 30.09.26.
//

import SwiftUI

@main
struct VPN_SplitterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Window("VPN Splitter", id: MenuBarView.mainWindowID) {
            ContentView(vm: appDelegate.vm)
                .modifier(CaptureOpenWindow { appDelegate.openWindow = $0 })
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let vm = ViewModel()
    var openWindow: OpenWindowAction?
    private var statusItem: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = StatusItemController(vm: vm) { [weak self] in
            self?.openWindow?(id: MenuBarView.mainWindowID)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

/// The status item lives outside any SwiftUI scene, so it borrows
/// the app's openWindow action from the main window.
private struct CaptureOpenWindow: ViewModifier {
    @Environment(\.openWindow) private var openWindow
    var capture: (OpenWindowAction) -> Void

    func body(content: Content) -> some View {
        content.onAppear { capture(openWindow) }
    }
}
