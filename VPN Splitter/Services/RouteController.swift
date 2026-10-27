//
//  RouteController.swift
//  VPN Splitter
//
//  Created by Mацвей Пажытных on 2.10.26.
//

import Foundation

enum RouteError: LocalizedError {
    case failed(String)

    var errorDescription: String? {
        if case .failed(let message) = self { return message }
        return nil
    }
}

final class RouteController: @unchecked Sendable {
    static let shared = RouteController()
    static let dir = "/usr/local/libexec/routerapp"

    private var watchdog: Process?

    var isInstalled: Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        p.arguments = ["-n", "-l", "\(Self.dir)/route-reset.zsh"]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return false }
        p.waitUntilExit()
        return p.terminationStatus == 0
    }

    func install() throws {
        guard let res = Bundle.main.resourcePath else {
            throw RouteError.failed("Нет каталога Resources")
        }
        let cmd = "/bin/zsh '\(res)/install.sh' '\(NSUserName())'"
        let source = "do shell script \"\(cmd)\" with administrator privileges"
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            throw RouteError.failed("Установка не удалась: \(error)")
        }
    }


    func apply(mode: WorkMode, interface: String, gateway: String, listURL: URL) async throws {
        let script = (mode == .blacklist) ? "route-blacklist.zsh" : "route-whitelist.zsh"
        try await Task.detached { [self] in
            try sudo(script, [interface, gateway, listURL.path])
            startWatchdogIfNeeded()
        }.value
    }

    func reset() async throws {
        try await Task.detached { [self] in
            try sudo("route-reset.zsh", [])
        }.value
    }

    func resetSync() {
        _ = try? sudo("route-reset.zsh", [])
    }


    @discardableResult
    private func sudo(_ script: String, _ args: [String]) throws -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        p.arguments = ["-n", "\(Self.dir)/\(script)"] + args

        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe

        try p.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()

        let text = String(data: data, encoding: .utf8) ?? ""
        guard p.terminationStatus == 0 else { throw RouteError.failed(text) }
        return text
    }

    private func startWatchdogIfNeeded() {
        if let w = watchdog, w.isRunning { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        p.arguments = ["-n", "\(Self.dir)/route-watchdog.zsh",
                       String(ProcessInfo.processInfo.processIdentifier)]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        watchdog = p
    }
}
