//
//  NetworkManage.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 30.09.26.
//

import Foundation

class NetworkManager {
    
    func resolveIPv4(_ host: String) async -> [String] {
        var hints = addrinfo(ai_flags: 0,
                             ai_family: AF_INET,
                             ai_socktype: SOCK_STREAM,
                             ai_protocol: 0,
                             ai_addrlen: 0,
                             ai_canonname: nil,
                             ai_addr: nil,
                             ai_next: nil)
        
        var res: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &res) == 0, let first = res else { return [] }
        defer {
            freeaddrinfo(res)
        }

        var ips = Set<String>()
        var ptr: UnsafeMutablePointer<addrinfo>? = first
        while let p = ptr {
            var buf = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(p.pointee.ai_addr, p.pointee.ai_addrlen, &buf, socklen_t(buf.count), nil, 0, NI_NUMERICHOST) == 0 {
                ips.insert(String(cString: buf))
            }
            ptr = p.pointee.ai_next
        }
        return Array(ips)
    }
    
    func listInterfaces() -> [NetInterface] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else {
            return []
        }
        
        var result: [String : NetInterface] = [:]
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        
        while let p = ptr {
            let name = String(cString: p.pointee.ifa_name)
            let flags = Int32(p.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0 && (flags & IFF_RUNNING) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            
            if !isLoopback {
                var ip: String? = result[name]?.ipv4
                if let addr = p.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) {
                    var buf = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &buf, socklen_t(buf.count), nil, 0, NI_NUMERICHOST) == 0 {
                        ip = String(cString: buf)
                    }
                    result[name] = NetInterface(name: name, ipv4: ip, isUp: isUp)
                }
            }
            ptr = p.pointee.ifa_next
        }
        
        return result.values
            .filter { $0.isUp }
            .sorted { $0.name < $1.name }
    }
}
