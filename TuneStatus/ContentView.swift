//
//  ContentView.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 03/03/2025.
//

import SwiftUI

// A helper that gives you access to the underlying NSWindow.
struct WindowAccessor: NSViewRepresentable {
    let minSize: NSSize
    let maxSize: NSSize

    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        // Dispatch to the next runloop cycle so that the view is attached to a window.
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.minSize = minSize
                window.maxSize = maxSize
                window.setContentSize(minSize)
            }
        }
        return nsView
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct ContentView: View {
    @EnvironmentObject var nowPlayingManager: NowPlayingManager
    // Initial state
    var body: some View {
        TuneStatusView(NowPlayingManager: nowPlayingManager)
            .background(WindowAccessor(
                minSize: NSSize(width: 320, height: 460),
                maxSize: NSSize(width: 320, height: 460))
            )
            .windowFullScreenBehavior(.disabled)
            .windowResizeBehavior(.disabled)
            .frame(minWidth: 320, idealWidth: 320, maxWidth: 320, minHeight: 480, idealHeight: 480, maxHeight: 480, alignment: .center)
            .cornerRadius(12)
    }
}

struct ContentViewPreview : PreviewProvider {
    static var previews: some View {
        let npmanager = NowPlayingManager()
        return ContentView().environmentObject(npmanager)
    }
}
