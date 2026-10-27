//
//  MenuBarView.swift
//  VPN Splitter
//

import SwiftUI

struct MenuBarView: View {
    static let mainWindowID = "main"

    @ObservedObject var vm: ViewModel
    @Environment(\.openWindow) private var openWindow
    @State private var interfaces: [NetInterface] = []
    @State private var angle: Double = 0

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
            HStack {
                Picker("", selection: $vm.selectedInterface) {
                    Text("Interface").tag(String?.none)
                    Divider()
                    ForEach(interfaces) { i in
                        Text("\(i.name)  \(i.ipv4 ?? "")").tag(String?.some(i.name))
                    }
                }
                .labelsHidden()
                Button {
                    refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(angle))
                }
                .help("Refresh interfaces")
            }
            .disabled(vm.isRunning)

            Divider()

            HStack {
                Button("Open VPN Splitter") {
                    openWindow(id: Self.mainWindowID)
                    NSApp.activate(ignoringOtherApps: true)
                }
                Spacer()
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear { interfaces = vm.getInterfaces() }
    }

    private func refresh() {
        interfaces = vm.getInterfaces()
        withAnimation(.easeInOut(duration: 0.5)) {
            angle += 360
        }
    }
}
