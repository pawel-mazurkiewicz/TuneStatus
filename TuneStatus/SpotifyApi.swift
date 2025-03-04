//
//  SpotifyApi.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 03/03/2025.
//

import Foundation

struct SpotifyApi {
    static let osaStart = "tell application \"Spotify\" to"
    
    static func getState() ->String{
        return executeScript(phrase: "player state")
    }

    static func getTitle() -> String{
        return executeScript(phrase: "name of current track")
    }
    
    static func getAlbum() -> String{
        return executeScript(phrase: "album of current track")
    }
    
    static func getArtist() -> String{
        return executeScript(phrase: "artist of current track")
    }
    
    static func getCover() -> NSData?{
        let imgScript = """
        tell application "Spotify"
            set artworkUrl to (artwork url of current track as text)
            return artworkUrl
        end tell

        """
        let url = URL(string:(executeScript(phrase: nil, bespokeScript: imgScript)))
        let result: NSData? = url != nil ? NSData(contentsOf:  url!) : nil
        
        return result
    }
    
    static func getVolume() -> String{
        return executeScript(phrase: "sound volume")
    }
    
    static func setVolume(level: Int){
        executeScript(phrase: "set sound volume to \(level)")
    }
    
    static func toNextTrack(){
        executeScript(phrase: "next track")
    }
    
    static func toPreviousTrack(){
        executeScript(phrase: "previous track")
    }
    
    static func toPlayPause(){
        executeScript(phrase: "playpause")
    }
    
    static func openSpotify(){
        executeScript(phrase: "activate")
    }
    
    static func executeScript(phrase: String? = "", bespokeScript: String? = nil) -> String{
        var output = ""
        var script : NSAppleScript? = NSAppleScript(source: "")
        if let bespokeScript {
            script = NSAppleScript(source: bespokeScript )
        } else {
            if let phrase {
                script = NSAppleScript(source: "\(osaStart) \(phrase)" )
            }
        }
        var errorInfo: NSDictionary?
        var descriptor = script?.executeAndReturnError(&errorInfo)
        if(descriptor?.stringValue != nil){
            output = descriptor!.stringValue!
        }
        return output
    }
    
    static func getDuration() -> String{
        return executeScript(phrase: "duration of current track")
    }
    
    static func getPosition() -> String{
        return executeScript(phrase: "position of current track")
    }
}
