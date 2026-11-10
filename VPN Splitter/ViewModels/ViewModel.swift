//
//  ViewModel.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 30.09.26.
//

import Foundation

class ViewModel : ObservableObject {
    @Published private(set) var lastError: String?
    
    private var netManager: NetworkManager = .init()
    private var routes = RouteController.shared
    
    @Published private(set) var isRunning: Bool = false
    @Published var blackList: [Domain] = [] {
        didSet { save(list: blackList, url: blacklistURL)}
    }
    @Published var whiteList: [Domain] = [] {
        didSet { save(list: whiteList, url: whitelistURL)}
    }
    
    @Published var selectedMode: WorkMode = .blacklist {
        didSet { UserDefaults.standard.set(selectedMode.rawValue, forKey: Self.modeKey) }
    }
    @Published var selectedInterface: String? {
        didSet {
            UserDefaults.standard.set(selectedInterface, forKey: Self.interfaceKey)
            updateInterfaces()
        }
    }
    /// Active interfaces, plus the selected one marked inactive if it is down.
    @Published private(set) var interfaces: [NetInterface] = []
    private var watcher: NetworkWatcher?
    private var selectedWasActive = false

    private static let modeKey = "selectedMode"
    private static let interfaceKey = "selectedInterface"
    
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
    private let ipURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("VPN Splitter", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("ips.txt")
    }()
    init() {
        blackList = load(url: blacklistURL)
        whiteList = load(url: whitelistURL)
        let defaults = UserDefaults.standard
        if let mode = defaults.string(forKey: Self.modeKey).flatMap(WorkMode.init(rawValue:)) {
            selectedMode = mode
        }
        selectedInterface = defaults.string(forKey: Self.interfaceKey)
        updateInterfaces()
        watcher = NetworkWatcher { [weak self] in self?.updateInterfaces() }
    }
    
    private func updateInterfaces() {
        var list = netManager.listInterfaces()
        let active = selectedInterface.map { name in list.contains { $0.name == name } } ?? false
        if let selected = selectedInterface, !active {
            list.append(NetInterface(name: selected, ipv4: nil, isUp: false))
        }
        interfaces = list

        defer { selectedWasActive = active }
        guard isRunning, let selected = selectedInterface, active != selectedWasActive else { return }
        if active {
            // The interface came back: its routes were dropped with it, apply them again.
            lastError = nil
            applyRoutes()
        } else {
            lastError = "Интерфейс \(selected) неактивен — маршруты восстановятся, когда он появится"
        }
    }
    
    func run() {
        lastError = nil
        if !routes.isInstalled {
            do {
                try routes.install()
            } catch {
                lastError = error.localizedDescription
                return
            }
        }
        guard let selectedInterface else { return }
        guard selectedWasActive else {
            lastError = "Интерфейс \(selectedInterface) неактивен"
            return
        }
        isRunning = true
        applyRoutes()
    }

    private func applyRoutes() {
        guard let selectedInterface else { return }
        guard let gateway = netManager.defaultGateway() else {
            lastError = "Не найден роутер на физическом интерфейсе (en*)"
            isRunning = false
            return
        }
        let mode = selectedMode
        Task { @MainActor in
            await resolveDomains()
            do {
                try await routes.reset()
                try await routes.apply(mode: mode, interface: selectedInterface, gateway: gateway, listURL: ipURL)
            } catch {
                lastError = error.localizedDescription
                isRunning = false
            }
        }
    }
    
    func stop() {
        isRunning = false
        lastError = nil
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



