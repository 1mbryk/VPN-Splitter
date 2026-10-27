//
//  VPN_SplitterApp.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 30.09.26.
//

import SwiftUI

@main
struct VPN_SplitterApp: App {
    @StateObject var vm: ViewModel = .init()
    var body: some Scene {
        Window("VPN Splitter", id: MenuBarView.mainWindowID) {
            ContentView(vm: vm)
        }

        MenuBarExtra {
            MenuBarView(vm: vm)
        } label: {
            MenuBarIcon(isRunning: vm.isRunning)
        }
        .menuBarExtraStyle(.window)
    }
}
