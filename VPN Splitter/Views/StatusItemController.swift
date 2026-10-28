//
//  StatusItemController.swift
//  VPN Splitter
//

import AppKit
import SwiftUI
import Combine

/// Menu bar icon and panel. Plain AppKit instead of MenuBarExtra: MenuBarExtra
/// re-renders its SwiftUI graph on every redraw of the status item.
final class StatusItemController: NSObject {
    private let vm: ViewModel
    private let openMainWindow: () -> Void
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private var cancellable: AnyCancellable?

    private static let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
    private static let symbol = NSImage(systemSymbolName: "network", accessibilityDescription: "VPN Splitter")

    /// Follows the menu bar's light/dark appearance.
    private static let idleIcon: NSImage? = {
        let image = symbol?.withSymbolConfiguration(config)
        image?.isTemplate = true
        return image
    }()

    private static let runningIcon: NSImage? = {
        let image = symbol?.withSymbolConfiguration(config.applying(.init(paletteColors: [.systemGreen])))
        image?.isTemplate = false
        return image
    }()

    init(vm: ViewModel, openMainWindow: @escaping () -> Void) {
        self.vm = vm
        self.openMainWindow = openMainWindow
        super.init()

        statusItem.button?.image = Self.idleIcon
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
        popover.behavior = .transient

        cancellable = vm.$isRunning
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.statusItem.button?.image = $0 ? Self.runningIcon : Self.idleIcon }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        guard let button = statusItem.button else { return }
        // Fresh view each time so the interface list is reloaded on open.
        let view = MenuBarView(vm: vm) { [weak self] in
            self?.popover.performClose(nil)
            self?.openMainWindow()
        }
        let host = NSHostingController(rootView: view)
        host.sizingOptions = .preferredContentSize
        popover.contentViewController = host
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
}
