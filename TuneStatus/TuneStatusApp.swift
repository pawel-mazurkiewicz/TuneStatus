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
    
    // Scrolling animation properties
    private var scrollTimer: Timer?
    private var scrollPosition: Int = 0
    private var scrollDirection: Int = 1
    private var fullText: String = ""
    private var playStatusIcon: String = ""
    private var isScrolling: Bool = false
    
    // About window reference
    private var aboutWindow: NSWindow?
    
    init(nowPlayingManager: NowPlayingManager) {
        self.nowPlayingManager = nowPlayingManager
        super.init()
        setupStatusItem()
        setupPopover()
        setupObservers()
        nowPlayingManager.playPause()
        nowPlayingManager.playPause()
    }
    
    deinit {
        stopScrolling()
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
        menu.addItem(NSMenuItem(title: "About TuneStatus", action: #selector(showAbout), keyEquivalent: ""))
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
    
    @objc private func showAbout() {
        // Close existing about window if it exists
        aboutWindow?.close()
        
        // Create the about view with dismiss closure
        let aboutView = AboutView(onDismiss: { [weak self] in
            self?.aboutWindow?.close()
            self?.aboutWindow = nil
        })
        
        let hostingController = NSHostingController(rootView: aboutView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = "About TuneStatus"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        
        // Store reference to prevent deallocation
        aboutWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
        
        self.playStatusIcon = entry.isPlaying ? "▶" : "⏸"
        
        if entry.trackName != "None" && !entry.trackName.isEmpty && 
           entry.artistName != "None" && !entry.artistName.isEmpty {
            // Create display string with track and artist
            let newFullText = "\(entry.trackName) - \(entry.artistName)"
            self.fullText = newFullText
            
            let maxLength = 40
            if newFullText.count > maxLength {
                // Start scrolling for long text
                startScrolling()
            } else {
                // Stop scrolling and show full text
                stopScrolling()
                button.title = "\(playStatusIcon) \(newFullText)"
            }
        } else if entry.trackName != "None" && !entry.trackName.isEmpty {
            // Fallback to just track name if artist is missing
            let newFullText = entry.trackName
            self.fullText = newFullText
            
            let maxLength = 30
            if newFullText.count > maxLength {
                startScrolling()
            } else {
                stopScrolling()
                button.title = "\(playStatusIcon) \(newFullText)"
            }
        } else {
            // No track playing
            stopScrolling()
            button.title = "♪ No Track"
        }
    }
    
    private func startScrolling() {
        guard !isScrolling else { return }
        
        isScrolling = true
        scrollPosition = 0
        scrollDirection = 1
        
        // Show initial text
        updateScrollingText()
        
        // Start timer for scrolling animation
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.updateScrollingText()
        }
    }
    
    private func stopScrolling() {
        isScrolling = false
        scrollTimer?.invalidate()
        scrollTimer = nil
        scrollPosition = 0
        scrollDirection = 1
    }
    
    private func updateScrollingText() {
        guard let button = statusItem?.button else { return }
        
        let maxDisplayLength = 40
        let textLength = fullText.count
        
        // If text fits, just show it
        if textLength <= maxDisplayLength {
            button.title = "\(playStatusIcon) \(fullText)"
            return
        }
        
        // Calculate the visible window of text
        let maxScrollPosition = textLength - maxDisplayLength
        
        // Get the current substring to display
        let startIndex = fullText.index(fullText.startIndex, offsetBy: scrollPosition)
        let endIndex = fullText.index(startIndex, offsetBy: min(maxDisplayLength, textLength - scrollPosition))
        let displayText = String(fullText[startIndex..<endIndex])
        
        button.title = "\(playStatusIcon) \(displayText)"
        
        // Update scroll position for next frame
        scrollPosition += scrollDirection
        
        // Reverse direction when we hit the boundaries
        if scrollPosition >= maxScrollPosition {
            scrollDirection = -1
            // Pause at the end for a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                // Continue scrolling if still active
            }
        } else if scrollPosition <= 0 {
            scrollDirection = 1
            scrollPosition = 0
            // Pause at the beginning for a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                // Continue scrolling if still active
            }
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
