//
//  InterfacePicker.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 1.10.26.
//

import SwiftUI

struct InterfacePicker: View {
    @Binding var selected: String?
    var interfaces: [NetInterface]

    var body: some View {
        Picker("", selection: $selected) {
            Text("Interface").tag(String?.none)
            Divider()
            ForEach(interfaces) { i in
                Text("\(i.name)  \(i.ipv4 ?? "")").tag(String?.some(i.name))
            }
        }
        .frame(maxWidth: 200)
    }
}

private struct InterfacePickerPreviewer: View {
    @State var selected: String?
    var networkManager = NetworkManager()
    var body: some View {
        InterfacePicker(selected: $selected, interfaces: networkManager.listInterfaces())
    }
}

#Preview {
    InterfacePickerPreviewer()
}
