//
//  InterfacePicker.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 1.10.26.
//

import SwiftUI

struct InterfacePicker: View {
    @Binding var selected: String?
    @State private var interfaces: [NetInterface] = []
    @State private var angle: Double = 0
    var getInterfaces: () -> [NetInterface]

    var body: some View {
        HStack {
            Picker("", selection: $selected) {
                Text("Interface").tag(String?.none)
                Divider()
                ForEach(interfaces) { i in
                    Text("\(i.name)  \(i.ipv4 ?? "")").tag(String?.some(i.name))
                }
            }
            Button {
                interfaces = getInterfaces()
                withAnimation(.easeInOut(duration: 0.5)) {
                    angle += 360
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(angle))

            }
        }
        .onAppear { interfaces = getInterfaces() }
        .frame(maxWidth: 200)
    }
}

private struct InterfacePickerPreviewer: View {
    @State var selected: String?
    var networkManager = NetworkManager()
    var body: some View {
        InterfacePicker(selected: $selected, getInterfaces: networkManager.listInterfaces)
    }
}

#Preview {
    InterfacePickerPreviewer()
}
