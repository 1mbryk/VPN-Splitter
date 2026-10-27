//
//  Enums.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 30.09.26.
//

import Foundation


enum WorkMode: String, CaseIterable, Identifiable {
    case blacklist = "Black list"
    case whitelist = "White list"
 
    var id: Self {self}
}
