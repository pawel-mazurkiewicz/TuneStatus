//
//  TuneStatusApp.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 03/03/2025.
//

import SwiftUI
import AppKit
import Combine

@main
struct TuneStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var nowPlayingManager = NowPlayingManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar controller with shared manager
        statusBarController = StatusBarController(nowPlayingManager: nowPlayingManager)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep the app running even when all windows are closed
        return false
    }
}

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var nowPlayingManager: NowPlayingManager
    private var cancellables = Set<AnyCancellable>()
    
    init(nowPlayingManager: NowPlayingManager) {
        self.nowPlayingManager = nowPlayingManager
        super.init()
        setupStatusItem()
        setupPopover()
        setupObservers()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "♪ No Track"
            button.action = #selector(handleStatusItemClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showRightClickMenu()
        } else {
            togglePopover()
        }
    }
    
    private func showRightClickMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show TuneStatus", action: #selector(togglePopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit TuneStatus", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Set target for menu items
        for item in menu.items {
            item.target = self
        }
        
        if let button = statusItem?.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: TuneStatusView(NowPlayingManager: nowPlayingManager)
        )
    }
    
    private func setupObservers() {
        // Observe changes to the current entry
        nowPlayingManager.$currentEntry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entry in
                self?.updateMenuBarTitle(with: entry)
            }
            .store(in: &cancellables)
    }
    
    private func updateMenuBarTitle(with entry: TuneStatusEntry) {
        guard let button = statusItem?.button else { return }
        
        let playStatusIcon = entry.isPlaying ? "▶" : "⏸"
        
        if entry.trackName != "None" && !entry.trackName.isEmpty && 
           entry.artistName != "None" && !entry.artistName.isEmpty {
            // Create display string with track and artist
            let fullText = "\(entry.trackName) - \(entry.artistName)"
            
            // Truncate if too long to fit in menu bar
            let maxLength = 40
            let displayText = fullText.count > maxLength 
                ? String(fullText.prefix(maxLength)) + "..." 
                : fullText
            
            button.title = "\(playStatusIcon) \(displayText)"
        } else if entry.trackName != "None" && !entry.trackName.isEmpty {
            // Fallback to just track name if artist is missing
            let maxLength = 30
            let displayName = entry.trackName.count > maxLength 
                ? String(entry.trackName.prefix(maxLength)) + "..." 
                : entry.trackName
            
            button.title = "\(playStatusIcon) \(displayName)"
        } else {
            button.title = "♪ No Track"
        }
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
