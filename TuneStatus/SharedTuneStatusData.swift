//
//  SharedTuneStatusData.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 04/03/2025.
//

import Foundation
import Cocoa

// A simple, codable struct to hold tune status data
struct SharedTuneStatusData: Codable {
    var trackName: String
    var artistName: String
    var albumName: String
    var currentTime: Double
    var duration: Double
    var isPlaying: Bool
    var lastUpdateTime: Date
    var appSource: String // "Music", "Spotify", or "generic"
    var artworkBase64: String? // Base64 encoded artwork image
    
    init(trackName: String, artistName: String, albumName: String,
         currentTime: Double, duration: Double, isPlaying: Bool,
         lastUpdateTime: Date, appSource: String, artworkBase64: String? = nil) {
        self.trackName = trackName
        self.artistName = artistName
        self.albumName = albumName
        self.currentTime = currentTime
        self.duration = duration
        self.isPlaying = isPlaying
        self.lastUpdateTime = lastUpdateTime
        self.appSource = appSource
        self.artworkBase64 = artworkBase64 // Base64 encoded artwork image
    }
    
    // Initialize with default values
    static var empty: SharedTuneStatusData {
        return SharedTuneStatusData(
            trackName: "None",
            artistName: "None",
            albumName: "None",
            currentTime: 0,
            duration: 1,
            isPlaying: false,
            lastUpdateTime: Date(),
            appSource: "generic",
            artworkBase64: nil
        )
    }
    
    // Initialize from a NowPlayingManager
    init(from manager: NowPlayingManager) {
        self.trackName = manager.currentEntry.trackName
        self.artistName = manager.currentEntry.artistName
        self.albumName = manager.currentEntry.albumName
        self.currentTime = manager.currentEntry.currentTime
        self.duration = manager.currentEntry.duration
        self.isPlaying = manager.currentEntry.isPlaying
        self.artworkBase64 = manager.currentEntry.artworkBase64
        self.lastUpdateTime = Date()
        
        // Convert enum to string for storage
        switch manager.app {
        case .Music:
            self.appSource = "Music"
        case .Spotify:
            self.appSource = "Spotify"
        case .generic:
            self.appSource = "generic"
        }
        
        // Convert artwork to base64 if available
        if let artwork = manager.currentEntry.artworkImage {
            // Convert NSImage to base64
            self.artworkBase64 = SharedTuneStatusData.convertImageToBase64(image: artwork)
        } else {
            self.artworkBase64 = nil
        }
    }
    
    // Helper method to decode base64 artwork back to NSImage
    func getArtworkImage() -> NSImage? {
        guard let base64String = artworkBase64 else { return nil }
        return SharedTuneStatusData.convertBase64ToImage(base64String: base64String)
    }
    
    // Convert NSImage to base64 string - direct approach
    static func convertImageToBase64(image: NSImage) -> String? {
        // First try to get PNG representation
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let newSize = CGSize(width: 320, height: 320)
            let format = NSBitmapImageRep.Format.thirtyTwoBitLittleEndian
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * Int(newSize.width)
            
            let context = CGContext(data: nil,
                                    width: Int(newSize.width),
                                    height: Int(newSize.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            
            if let context = context {
                // Draw the resized image
                context.draw(cgImage, in: CGRect(origin: .zero, size: newSize))
                
                if let resizedImage = context.makeImage() {
                    let rep = NSBitmapImageRep(cgImage: resizedImage)
                    if let pngData = rep.representation(using: .png, properties: [:]) {
                        return pngData.base64EncodedString()
                    }
                }
            }
        }
        
        // Fallback to try data directly
        if let tiffData = image.tiffRepresentation {
            return tiffData.base64EncodedString()
        }
        
        // Log the error and return nil if all else fails
        print("Failed to convert image to base64 - all methods failed")
        return nil
    }
    
    // Convert base64 string back to NSImage - with improved error handling
    static func convertBase64ToImage(base64String: String) -> NSImage? {
        // Try to create Data from the base64 string
        guard let imageData = Data(base64Encoded: base64String) else {
            print("Failed to decode base64 string to data")
            return nil
        }
        
        // Try different approaches to create an image
        
        // Approach 1: Direct NSImage from data
        if let image = NSImage(data: imageData) {
            return image
        }
        
        // Approach 2: Try through bitmap rep
        if let bitmap = NSBitmapImageRep(data: imageData) {
            let image = NSImage(size: bitmap.size)
            image.addRepresentation(bitmap)
            return image
        }
        
        print("Failed to create image from data - all methods failed")
        return nil
    }
    
    // Extension method to help debug this issue
    func debugImageConversion(image: NSImage){
        print("Original image size: \(image.size)")
        
        // Check if we can get tiff representation
        if let tiffData = image.tiffRepresentation {
            print("Successfully got TIFF representation, size: \(tiffData.count) bytes")
            
            // Try to create a bitmap from the TIFF data
            if let bitmap = NSBitmapImageRep(data: tiffData) {
                print("Successfully created bitmap from TIFF data")
                print("Bitmap size: \(bitmap.size)")
                print("Bits per sample: \(bitmap.bitsPerSample)")
                print("Samples per pixel: \(bitmap.samplesPerPixel)")
                print("Has alpha: \(bitmap.hasAlpha)")
                print("Color space: \(bitmap.colorSpaceName.rawValue ?? "unknown")")
                
                // Try to get JPEG representation
                if let jpegData = bitmap.representation(using: .jpeg, properties: [:]) {
                    print("Successfully got JPEG representation, size: \(jpegData.count) bytes")
                } else {
                    print("Failed to get JPEG representation from bitmap")
                }
                
                // Try to get PNG representation (may be more reliable)
                if let pngData = bitmap.representation(using: .png, properties: [:]) {
                    print("Successfully got PNG representation, size: \(pngData.count) bytes")
                } else {
                    print("Failed to get PNG representation from bitmap")
                }
            } else {
                print("Failed to create bitmap from TIFF data")
            }
        } else {
            print("Failed to get TIFF representation")
        }
        
        // Try CGImage path
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            print("Successfully got CGImage")
            print("CGImage width: \(cgImage.width), height: \(cgImage.height)")
            
            // Try to create a bitmap from CGImage
            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            print("Successfully created bitmap from CGImage")
            
            // Try to get PNG representation
            if let pngData = bitmap.representation(using: .png, properties: [:]) {
                print("Successfully got PNG representation from CGImage path, size: \(pngData.count) bytes")
            } else {
                print("Failed to get PNG representation from CGImage path")
            }
        } else {
            print("Failed to get CGImage")
        }
    }
}

// Extension for easy saving and loading via UserDefaults
extension SharedTuneStatusData {
    // Save to user defaults
    func save() {
        let defaults = UserDefaults(suiteName: "group.com.chillaid.art.tunestatus")
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            defaults?.set(data, forKey: "tuneStatusData")
            defaults?.synchronize()
        } catch {
            print("Failed to encode tune status data: \(error)")
        }
    }
    
    // Load from user defaults
    static func load() -> SharedTuneStatusData {
        let defaults = UserDefaults(suiteName: "group.com.chillaid.art.tunestatus")
        
        // Return default empty data if nothing is found
        guard let data = defaults?.data(forKey: "tuneStatusData") else {
            return .empty
        }
        
        do {
            let decoder = JSONDecoder()
            let tuneData = try decoder.decode(SharedTuneStatusData.self, from: data)
            return tuneData
        } catch {
            print("Failed to decode tune status data: \(error)")
            return .empty
        }
    }
}
