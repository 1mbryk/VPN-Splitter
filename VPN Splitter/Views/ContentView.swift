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
                    .disabled(vm.isRunning)
                Picker("Mode", selection: $vm.selectedMode) {
                    ForEach(WorkMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .disabled(vm.isRunning)
                Button("", systemImage: vm.isRunning ? "stop.fill" : "play.fill") {
                    if vm.isRunning {
                        vm.stop()
                    } else {
                        vm.run()
                    }
                }
                .disabled(vm.selectedInterface == nil)
                .frame(width:25, height: 25)
            }
                
        }
    }
}

#Preview {
    ContentView(vm: .init())
        .frame(minWidth: 600, minHeight: 400)
}
