//
//  NetworkWatcher.swift
//  VPN Splitter
//

import Foundation
import SystemConfiguration

/// Calls `onChange` on the main queue when interfaces appear/disappear or
/// their IPv4 addresses change. Bursts (e.g. a VPN connecting) are coalesced.
final class NetworkWatcher {
    private var store: SCDynamicStore?
    private var pending: DispatchWorkItem?
    private let onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange

        var context = SCDynamicStoreContext(version: 0,
                                            info: Unmanaged.passUnretained(self).toOpaque(),
                                            retain: nil, release: nil, copyDescription: nil)
        store = SCDynamicStoreCreate(nil, "VPN Splitter" as CFString, { _, _, info in
            guard let info else { return }
            Unmanaged<NetworkWatcher>.fromOpaque(info).takeUnretainedValue().scheduleUpdate()
        }, &context)
        guard let store else { return }

        let keys = ["State:/Network/Interface"] as CFArray
        let patterns = ["State:/Network/Interface/[^/]+/IPv4"] as CFArray
        SCDynamicStoreSetNotificationKeys(store, keys, patterns)
        SCDynamicStoreSetDispatchQueue(store, .main)
    }

    deinit {
        if let store { SCDynamicStoreSetDispatchQueue(store, nil) }
    }

    private func scheduleUpdate() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.onChange() }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }
}
