//
//  TuneStatusView.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 03/03/2025.
//
import SwiftUI

struct TuneStatusView: View {
    @State var NowPlayingManager: NowPlayingManager
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 8) {
            // Album artwork
            if let artwork = NowPlayingManager.currentEntry.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 320, height: 320)
                    .cornerRadius(6)
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 240, height: 160)
                    .foregroundColor(.secondary)
            }
            
            // Track info
            Text(NowPlayingManager.currentEntry.trackName)
                .font(.headline)
                .lineLimit(1)
            
            Text(NowPlayingManager.currentEntry.artistName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            // Progress bar
            HStack {
                Text(formatTime(NowPlayingManager.currentEntry.currentTime))
                    .font(.caption)
                    .monospacedDigit()
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 4)
                            .opacity(0.3)
                            .foregroundColor(.gray)
                            .clipShape(Capsule())
                        
                        Rectangle()
                            .frame(width: min(CGFloat(NowPlayingManager.currentEntry.progressPercentage) * geometry.size.width, geometry.size.width), height: 4)
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .frame(height: 4)
                Text(formatTime(NowPlayingManager.currentEntry.duration))
                    .font(.caption)
                    .monospacedDigit()
            }
            
            // Controls
            ZStack {
                // This makes the entire widget clickable but with different zones
                VStack {
                    HStack(spacing: 20) {
                        // Previous button area (left third)
                        Button("Back", systemImage: "backward.fill", action: { NowPlayingManager.prevTrack() })
                            .labelStyle(.iconOnly)
                            .buttonStyle(PlainButtonStyle())
                        // Play/pause button area (middle third)
                        Button(
                            NowPlayingManager.currentEntry.isPlaying ? "Pause" : "Play",
                            systemImage: NowPlayingManager.currentEntry.isPlaying ? "pause.fill" : "play.fill",
                            action: {
                                NowPlayingManager.playPause()
                            }
                        )
                            .labelStyle(.iconOnly)
                            .buttonStyle(PlainButtonStyle())
                        // Next button area (right third)
                        Button("Forward", systemImage: "forward.fill", action: {
                            NowPlayingManager.nextTrack()
                        })
                            .labelStyle(.iconOnly)
                            .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 4)
                }.padding(.bottom, 20)
            }
            .padding(.top, 4)
        }
        .frame(minWidth: 320, idealWidth: 320, maxWidth: 320, minHeight: 480, idealHeight: 480, maxHeight: 480, alignment: .center)
        .onReceive(timer) { _ in
            if (NowPlayingManager.currentEntry.isPlaying) {
                NowPlayingManager.currentEntry.currentTime += 1
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct TuneStatusPreview : PreviewProvider {
    static var previews: some View {
        let npmanager = NowPlayingManager()
        return TuneStatusView(NowPlayingManager: npmanager).frame(width: 320, height: 480)
    }
}
