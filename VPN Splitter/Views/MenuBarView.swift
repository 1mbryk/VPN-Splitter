//
//  MenuBarView.swift
//  VPN Splitter
//

import SwiftUI

struct MenuBarView: View {
    static let mainWindowID = "main"

    @ObservedObject var vm: ViewModel
    var openMainWindow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(vm.isRunning ? .green : .secondary)
                    .frame(width: 8, height: 8)
                Text(vm.isRunning ? "Running" : "Stopped")
                    .font(.headline)
                Spacer()
                Button(vm.isRunning ? "Stop" : "Start",
                       systemImage: vm.isRunning ? "stop.fill" : "play.fill") {
                    if vm.isRunning {
                        vm.stop()
                    } else {
                        vm.run()
                    }
                }
                .disabled(vm.selectedInterface == nil)
            }

            if let error = vm.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Text("Mode").font(.caption).foregroundStyle(.secondary)
            Picker("", selection: $vm.selectedMode) {
                ForEach(WorkMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(vm.isRunning)

            Text("Interface").font(.caption).foregroundStyle(.secondary)
            Picker("", selection: $vm.selectedInterface) {
                Text("Interface").tag(String?.none)
                Divider()
                ForEach(vm.interfaces) { i in
                    Text(i.title).tag(String?.some(i.name))
                }
            }
            .labelsHidden()
            .disabled(vm.isRunning)

            Divider()

            HStack {
                Button("Open VPN Splitter") {
                    openMainWindow()
                }
                Spacer()
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding()
        .frame(width: 300)
    }
}
