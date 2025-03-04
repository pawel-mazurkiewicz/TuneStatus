//
//  WidgetNowPlayingManager.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 04/03/2025.
//

import SwiftUI
import WidgetKit

// A simplified version of NowPlayingManager for the widget
class WidgetNowPlayingManager: ObservableObject {
    @Published var currentEntry: TuneStatusEntry
    var app: supportedApps
    
    init(from sharedData: SharedTuneStatusData) {
        // Create entry from shared data
        
        self.currentEntry = TuneStatusEntry(
            date: Date(),
            trackName: sharedData.trackName,
            artistName: sharedData.artistName,
            albumName: sharedData.albumName,
            artworkImage: nil,
            currentTime: sharedData.currentTime,
            duration: sharedData.duration,
            isPlaying: sharedData.isPlaying,
            artworkBase64: sharedData.artworkBase64
        )
        
        // Convert string app source back to enum
        switch sharedData.appSource {
        case "Music":
            self.app = .Music
        case "Spotify":
            self.app = .Spotify
        default:
            self.app = .generic
        }
        
        // Get artwork from base64 if available
        var artwork: NSImage? = nil
        if let image = sharedData.getArtworkImage() {
            artwork = image
            self.currentEntry.artworkImage = artwork
        }
    }
    
    // Default initializer for previews with sample artwork
    init() {
        // First, initialize all stored properties
        let previewArtwork = WidgetNowPlayingManager.createDummyArtwork() // Using static method
        
        self.currentEntry = TuneStatusEntry(
            date: Date(),
            trackName: "Preview Track",
            artistName: "Preview Artist",
            albumName: "Preview Album",
            artworkImage: previewArtwork,
            currentTime: 60,
            duration: 180,
            isPlaying: true
        )
        self.app = .Music
        
        // Now you can call any instance methods if needed
    }

    // Make this a type (static) method instead of an instance method
    private static func createDummyArtwork() -> NSImage? {
        let size = NSSize(width: 200, height: 200)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Draw a gradient background
        let gradient = NSGradient(colors: [NSColor.blue, NSColor.purple])
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
        
        // Draw text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        let text = "PREVIEW"
        let textRect = NSRect(x: 0, y: 80, width: size.width, height: 40)
        text.draw(in: textRect, withAttributes: attributes)
        
        image.unlockFocus()
        
        return image
    }
}
