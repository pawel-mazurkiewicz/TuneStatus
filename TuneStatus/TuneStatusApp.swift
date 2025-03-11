//
//  TuneStatusApp.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 03/03/2025.
//

import SwiftUI

@main
struct TuneStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var nowPlayingManager = NowPlayingManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(nowPlayingManager)
        }.windowStyle(HiddenTitleBarWindowStyle())
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {

    }
}
