//
//  TuneStatusApp.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 03/03/2025.
//

import SwiftUI

@main
struct TuneStatusApp: App {
    @StateObject private var nowPlayingManager = NowPlayingManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(nowPlayingManager)
        }
    }
}

