//
//  ViewModel.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 30.09.26.
//

import Foundation

class ViewModel : ObservableObject {
    @Published var gateway: String = "192.168.1.1"
    
    private var netManager: NetworkManager = .init()
    private var routes = RouteController.shared
    
    @Published private(set) var isRunning: Bool = false
    @Published var blackList: [Domain] = [] {
        didSet { save(list: blackList, url: blacklistURL)}
    }
    @Published var whiteList: [Domain] = [] {
        didSet { save(list: whiteList, url: whitelistURL)}
    }
    
    @Published var selectedMode: WorkMode = .blacklist
    @Published var selectedInterface: String?
    
    private let blacklistURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("VPN Splitter", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("blacklist.json")
    }()
    private let whitelistURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("VPN Splitter", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("whitelist.json")
    }()
    private let ipURL: URL = .init(fileURLWithPath: "/Users/macvejpazh/Documents/ips.txt")
    init() {
        blackList = load(url: blacklistURL)
        whiteList = load(url: whitelistURL)
    }
    
    func getInterfaces() -> [NetInterface] {
        return netManager.listInterfaces()
    }
    
    func run() {
        
        if !routes.isInstalled {
            do {
                try routes.install()
            } catch {
                print(error.localizedDescription)
                return
            }
        }
        Task {
            await resolveDomains()
            do {
                try await routes.reset()
                guard let selectedInterface = selectedInterface else { return }
                try await routes.apply(mode: selectedMode, interface: selectedInterface, gateway: gateway, listURL: ipURL)
            } catch {
                print(error.localizedDescription)
            }
        }
        isRunning = true
        
        
    }
    
    func stop() {
        isRunning = false
        routes.resetSync()
    }
    
    private func save (list: [Domain], url: URL) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        try? data.write(to: url, options: .atomic)
    }
    
    private func load (url: URL) -> [Domain] {
        guard let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Domain].self, from: data)
        else { return [] }
        return list
    }
    
    private func resolveDomains() async {
        let domains = switch selectedMode {
            case .blacklist: blackList
            case .whitelist: whiteList
        }
        
        var ips: [String] = []
        for domain in domains {
            print("Starting resovling \(domain.name)")
            let resolved = await netManager.resolveIPv4(domain.name)
            print("Resolved: \(resolved.count) ips")
            ips.append(contentsOf: resolved )
            
        }
        
        let text = ips.joined(separator: "\n")
        try? text.data(using: .utf8)?.write(to: ipURL, options: .atomic)
        
    }
    
    
}



