//
//  MusicApi.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 04/03/2025.
//

import Foundation

struct MusicApi {
    static let osaStart = "tell application \"Music\" to"
    
    static func getState() -> String {
        return executeScript(phrase: "player state")
    }

    static func getTitle() -> String {
        return executeScript(phrase: "name of current track")
    }
    
    static func getAlbum() -> String {
        return executeScript(phrase: "album of current track")
    }
    
    static func getArtist() -> String {
        return executeScript(phrase: "artist of current track")
    }
    
    static func getCover() -> NSData? {
        let imgScript = """
        tell application "Music"
            if exists artwork 1 of current track then
                return data of artwork 1 of current track
            else
                return missing value
            end if
        end tell
        """
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: imgScript) else { return nil }
        let descriptor = script.executeAndReturnError(&errorInfo)
        
        if let errorInfo = errorInfo {
            print("AppleScript Error: \(errorInfo)")
            return nil
        }
        
        // Check if the descriptor is of type JPEG.
        if descriptor.descriptorType == typeJPEG {
            return descriptor.data as NSData
        }
        
        return nil
    }
    
    static func getVolume() -> String {
        return executeScript(phrase: "sound volume")
    }
    
    static func setVolume(level: Int) {
        executeScript(phrase: "set sound volume to \(level)")
    }
    
    static func toNextTrack() {
        executeScript(phrase: "next track")
    }
    
    static func toPreviousTrack() {
        executeScript(phrase: "previous track")
    }
    
    static func toPlayPause() {
        executeScript(phrase: "playpause")
    }
    
    static func openMusic() {
        executeScript(phrase: "activate")
    }
    
    static func getDuration() -> String {
        return executeScript(phrase: "duration of current track")
    }
    
    static func getPosition() -> TimeInterval {
        let positionScript =
        """
            try
                tell application "Music" to set T to player position
                set H to T div 3600
                set S to T mod 3600
                set M to S div 60
                set S to S mod 60
                if M < 10 then set M to "0" & M
                if S < 10 then set S to "0" & S
                set T to (H as text) & ":" & M & ":" & S
            on error
                set T to "No song playing"
            end try
        """
        
        let timeString = executeScript(phrase: nil, bespokeScript: positionScript)
        let parts = timeString.components(separatedBy: ":")
        guard parts.count == 3,
              let hours = Double(parts[0]),
              let minutes = Double(parts[1]) else {
            return 0
        }
        
        // Split the seconds component by comma to ignore milliseconds
        let secondsParts = parts[2].components(separatedBy: ",")
        guard let seconds = Double(secondsParts[0]) else {
            return 0
        }
        
        // Calculate total seconds
        return hours * 3600 + minutes * 60 + seconds
    }
    
    static func executeScript(phrase: String? = "", bespokeScript: String? = nil) -> String {
        var output = ""
        var script: NSAppleScript? = NSAppleScript(source: "")
        if let bespokeScript = bespokeScript {
            script = NSAppleScript(source: bespokeScript)
        } else if let phrase = phrase {
            script = NSAppleScript(source: "\(osaStart) \(phrase)")
        }
        var errorInfo: NSDictionary?
        let descriptor = script?.executeAndReturnError(&errorInfo)
        if let descriptorString = descriptor?.stringValue {
            output = descriptorString
        }
        return output
    }
}
