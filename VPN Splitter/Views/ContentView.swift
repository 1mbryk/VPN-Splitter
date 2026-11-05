//
//  ContentView.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 30.09.26.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var vm: ViewModel
    var body: some View {
        TabView {
            DomainList(domains: $vm.blackList)
                .tabItem { Label("Black List", systemImage: "list.bullet") }

            DomainList(domains: $vm.whiteList)
                .tabItem { Label("White List", systemImage: "list.bullet") }
        }
        .safeAreaInset(edge: .bottom) {
            if let error = vm.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                InterfacePicker(selected: $vm.selectedInterface, interfaces: vm.interfaces)
                    .padding(.horizontal, 6)
                    .disabled(vm.isRunning)
                Picker("Mode", selection: $vm.selectedMode) {
                    ForEach(WorkMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .padding(.horizontal, 6)
                .disabled(vm.isRunning)
            }
            // Separate item so it gets its own round background instead of
            // sharing the pickers' capsule.
            ToolbarItem {
                Button {
                    if vm.isRunning {
                        vm.stop()
                    } else {
                        vm.run()
                    }
                } label: {
                    Image(systemName: vm.isRunning ? "stop.fill" : "play.fill")
                        .frame(width: 16, height: 16)
                        .padding(4)
                }
                .help(vm.isRunning ? "Stop" : "Start")
                .disabled(vm.selectedInterface == nil)
            }
        }
    }
}

#Preview {
    ContentView(vm: .init())
        .frame(minWidth: 600, minHeight: 400)
}
