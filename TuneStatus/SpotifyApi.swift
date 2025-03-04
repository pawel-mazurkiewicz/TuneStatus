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
        return genericApi.executeScript(phrase: "player state", bespokeScript: nil, osaString: osaStart)
    }

    static func getTitle() -> String{
        return genericApi.executeScript(phrase: "name of current track", bespokeScript: nil, osaString: osaStart)
    }
    
    static func getAlbum() -> String{
        return genericApi.executeScript(phrase: "album of current track", bespokeScript: nil, osaString: osaStart)
    }
    
    static func getArtist() -> String{
        return genericApi.executeScript(phrase: "artist of current track", bespokeScript: nil, osaString: osaStart)
    }
    
    static func getCover() -> NSData?{
        let imgScript = """
        tell application "Spotify"
            set artworkUrl to (artwork url of current track as text)
            return artworkUrl
        end tell

        """
        let url = URL(string:(genericApi.executeScript(phrase: nil, bespokeScript: imgScript)))
        let result: NSData? = url != nil ? NSData(contentsOf:  url!) : nil
        
        return result
    }
    
    static func getVolume() -> String{
        return genericApi.executeScript(phrase: "sound volume", bespokeScript: nil, osaString: osaStart)
    }
    
    static func setVolume(level: Int){
        genericApi.executeScript(phrase: "set sound volume to \(level)", bespokeScript: nil, osaString: osaStart)
    }
    
    static func toNextTrack(){
        genericApi.executeScript(phrase: "next track", bespokeScript: nil, osaString: osaStart)
    }
    
    static func toPreviousTrack(){
        genericApi.executeScript(phrase: "previous track", bespokeScript: nil, osaString: osaStart)
    }
    
    static func toPlayPause(){
        genericApi.executeScript(phrase: "playpause", bespokeScript: nil, osaString: osaStart)
    }
    
    static func openSpotify(){
        genericApi.executeScript(phrase: "activate", bespokeScript: nil, osaString: osaStart)
    }
    
    static func getDuration() -> String{
        return genericApi.executeScript(phrase: "duration of current track", bespokeScript: nil, osaString: osaStart)
    }
    
    static func getPosition() -> String{
        return genericApi.executeScript(phrase: "position of current track", bespokeScript: nil, osaString: osaStart)
    }
}
