//
//  NowPlayingManager.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 03/03/2025.
//

import Foundation
import Cocoa
import WidgetKit

struct TuneStatusEntry {
    var date: Date
    var trackName: String
    var artistName: String
    var albumName: String
    var artworkImage: NSImage?
    var currentTime: TimeInterval
    var duration: TimeInterval
    var isPlaying: Bool
    var artworkBase64: String?
    
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
    case generic
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
    // Make app property accessible (previously private)
    var app: supportedApps = .generic
    
    init() {
        // Setup everything
        setupNotificationObservers()
        print("Notification observers set up")
        
        // Initial update attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            print("Trying to get first update")
            genericApi.pressPlayPauseKey()
            genericApi.pressPlayPauseKey()
        }
        
        // Set up timer to periodically update shared data for the widget
        setupSharedDataTimer()
        
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
    
    // Setup timer to update shared data periodically
    private func setupSharedDataTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if (self.currentEntry.isPlaying) {
                 self.currentEntry.currentTime += 1
//                 self.updateSharedData()
             }
        }
    }
    
    // Update shared data for widgets
    private func updateSharedData() {
        // Create shared data from current state
        let sharedData = SharedTuneStatusData(from: self)
        
        // Save to shared container
        sharedData.save()
        
        if debugMode {
            print("Updated shared data for widget: \(sharedData.trackName)")
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
                guard let coverImage = NSImage(data: artworkData) else { return }
                currentEntry.artworkBase64 = SharedTuneStatusData.convertImageToBase64(image: coverImage)
                updateSharedData()
                WidgetCenter.shared.reloadTimelines(ofKind: "TuneStatus Widget")
            }
        }
        lastUpdateTime = Date()
        
        // Update shared data for widget
        updateSharedData()
        WidgetCenter.shared.reloadTimelines(ofKind: "TuneStatus Widget")
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
        
        // Duration and position
        if let duration = userInfo["Duration"] as? Double {
            currentEntry.duration = duration / 1000.0 // Spotify returns in milliseconds
        }
        
        if let position = userInfo["Playback Position"] as? Double {
            currentEntry.currentTime = position
        }
        
        if let hasArtwork = userInfo["Has Artwork"] as? Bool, hasArtwork, !sameTrack {
            // Dispatch the cover download to a background thread.
            DispatchQueue.global(qos: .background).async { [weak self] in
                // Call SpotifyApi.getCover() on a background thread.
                guard let imageData = SpotifyApi.getCover() as? Data,
                      let coverImage = NSImage(data: imageData) else {
                    return
                }
                    
                // Update the UI on the main thread.
                DispatchQueue.main.async {
                    self?.currentEntry.artworkImage = coverImage
                }
                
                DispatchQueue.main.async { [weak self] in
                    guard let coverImage = NSImage(data: imageData) else { return }
                    self?.currentEntry.artworkBase64 = SharedTuneStatusData.convertImageToBase64(image: coverImage)
                    self?.updateSharedData()
                    WidgetCenter.shared.reloadTimelines(ofKind: "TuneStatus Widget")
                }
            }
        } else {
            // Update shared data for widget
            updateSharedData()
            WidgetCenter.shared.reloadTimelines(ofKind: "TuneStatus Widget")
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
            case .generic:
                genericApi.pressPlayPauseKey()
        }
    }
        
    func nextTrack() {
        switch app {
            case .Spotify:
                SpotifyApi.toNextTrack()
            case .Music:
                MusicApi.toNextTrack()
            case .generic:
                genericApi.pressNextTrackKey()
            }
        }
        
    func prevTrack() {
        currentEntry.currentTime = 0
        switch app {
        case .Spotify:
            SpotifyApi.toPreviousTrack()
        case .Music:
            MusicApi.toPreviousTrack()
        case .generic:
            genericApi.pressPreviousTrackKey()
        }
    }
}
