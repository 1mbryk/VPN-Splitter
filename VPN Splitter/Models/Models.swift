//
//  Models.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 30.09.26.
//

import Foundation


struct Domain: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
}

struct NetInterface: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let ipv4: String?
    let isUp: Bool

    var title: String {
        isUp ? "\(name)  \(ipv4 ?? "")" : "\(name)  (inactive)"
    }
}
