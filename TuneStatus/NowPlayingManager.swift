//
//  NowPlayingManager.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 03/03/2025.
//

import Foundation
import Cocoa

struct TuneStatusEntry {
    var date: Date
    var trackName: String
    var artistName: String
    var albumName: String
    var artworkImage: NSImage?
    var currentTime: TimeInterval
    var duration: TimeInterval
    var isPlaying: Bool
    
    // Computed property for progress percentage
    var progressPercentage: Double {
        duration > 0 ? currentTime / duration : 0
    }
}

enum buttonState {
    case play
    case pause
    case back
    case forward
}

enum supportedApps {
    case Music
    case Spotify
}

class NowPlayingManager : ObservableObject {
    // Published properties for UI updates
    @Published var currentEntry = TuneStatusEntry(
        date: Date(),
        trackName: "None",
        artistName: "None",
        albumName: "None",
        artworkImage: nil,
        currentTime: 0,
        duration: 1,
        isPlaying: false
    )
    
    // Private properties
    private var timer: Timer?
    private var lastUpdateTime: Date = Date()
    private var debugMode: Bool = true
    
    // Track the last source of data
    private var lastDataSource: String = "none"
    private var app: supportedApps = .Spotify
    
    init() {
        // Setup everything
        setupNotificationObservers()
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        
        // Initial update attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            //            self?.updateNowPlayingInfo()
            print("Trying to update")
        }
        
        if debugMode {
            print("NowPlayingManager initialized")
        }
    }
    
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    // MARK: - Setup Methods
    
    private func setupNotificationObservers() {
        // Distributed notification center for inter-app communication
        let distCenter = DistributedNotificationCenter.default()
        
        // iTunes/Music notifications
        distCenter.addObserver(
            self,
            selector: #selector(handleiTunesNotification(_:)),
            name: NSNotification.Name("com.apple.iTunes.playerInfo"),
            object: nil
        )
        
        // Spotify notifications
        distCenter.addObserver(
            self,
            selector: #selector(handleSpotifyNotification(_:)),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
        
        if debugMode {
            print("Notification observers set up")
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleiTunesNotification(_ notification: Notification) {
        if debugMode {
            print("Received iTunes/Music notification: \(notification.userInfo ?? [:])")
        }
        
        if app != .Music {
            currentEntry.artworkImage = nil
        }
        
        var sameTrack = false
        
        guard let userInfo = notification.userInfo else { return }
        
        // Check playing state
        if let playerState = userInfo["Player State"] as? String {
            currentEntry.isPlaying = playerState == "Playing"
        }
        
        // Get track info
        if let name = userInfo["Name"] as? String {
            if currentEntry.trackName == name {
                sameTrack = true
            }
            currentEntry.trackName = name
            lastDataSource = "Music notification"
            app = .Music
        }
        
        if let artistName = userInfo["Artist"] as? String {
            currentEntry.artistName = artistName
        }
        
        if let albumName = userInfo["Album"] as? String {
            currentEntry.albumName = albumName
        }
        
        // Track timing
        if let totalTime = userInfo["Total Time"] as? Int {
            currentEntry.duration = Double(totalTime) / 1000.0
        }
        
        currentEntry.currentTime = MusicApi.getPosition()
        
        // Try to get artwork data directly from notification
        if !sameTrack {
            if let artworkData = MusicApi.getCover() as? Data,
               let image = NSImage(data: artworkData) {
                currentEntry.artworkImage = image
            }
        }
        lastUpdateTime = Date()
    }
    
    @objc private func handleSpotifyNotification(_ notification: Notification) {
        if debugMode {
            print("Received Spotify notification: \(notification.userInfo ?? [:])")
        }
        
        if app != .Spotify {
            currentEntry.artworkImage = nil
        }
        
        var sameTrack = false
        // Process directly from notification data since AppleScript might fail
        guard let userInfo = notification.userInfo else { return }
        
        // Update playing state
        if let playerState = userInfo["Player State"] as? String {
            currentEntry.isPlaying = playerState == "Playing"
        }
        
        // Track info
        if let name = userInfo["Name"] as? String {
            if currentEntry.trackName == name {
                sameTrack = true
            }
            currentEntry.trackName = name
            lastDataSource = "Spotify notification"
            app = .Spotify
        }
        
        if let artistName = userInfo["Artist"] as? String {
            currentEntry.artistName = artistName
        }
        
        if let albumName = userInfo["Album"] as? String {
            currentEntry.albumName = albumName
        }
        
        if let hasArtwork = userInfo["Has Artwork"] as? Bool, hasArtwork, !sameTrack {
            // Dispatch the cover download to a background thread.
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                // Call SpotifyApi.getCover() on a background thread.
                guard let imageData = SpotifyApi.getCover() as? Data,
                      let coverImage = NSImage(data: imageData) else {
                    return
                }
                
                // Update the UI on the main thread.
                DispatchQueue.main.async {
                    self?.currentEntry.artworkImage = coverImage
                }
            }
        }
        
        // Duration and position
        if let duration = userInfo["Duration"] as? Double {
            currentEntry.duration = duration / 1000.0 // Spotify returns in milliseconds
        }
        
        if let position = userInfo["Playback Position"] as? Double {
            currentEntry.currentTime = position
        }
        
        lastUpdateTime = Date()
    }
    
    //MARK: Control Streams
    func playPause() {
        switch app {
        case .Spotify:
            SpotifyApi.toPlayPause()
        case .Music:
            MusicApi.toPlayPause()
        }
    }
    
    func nextTrack() {
        switch app {
        case .Spotify:
            SpotifyApi.toNextTrack()
        case .Music:
            MusicApi.toNextTrack()
        }
    }
    
    func prevTrack() {
        currentEntry.currentTime = 0
        switch app {
        case .Spotify:
            SpotifyApi.toPreviousTrack()
        case .Music:
            MusicApi.toPreviousTrack()
        }
    }
}
