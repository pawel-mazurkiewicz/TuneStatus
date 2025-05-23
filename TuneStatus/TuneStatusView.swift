//
//  TuneStatusView.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 03/03/2025.
//
import SwiftUI

struct TuneStatusView<T>: View where T: ObservableObject {
    @ObservedObject var NowPlayingManager: T
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            // Display the current track information
            if let npm = NowPlayingManager as? NowPlayingManager {
                // Full app version
                trackInfoView(entry: npm.currentEntry)
                // Controls
                ZStack {
                    VStack {
                        HStack(spacing: 20) {
                            // Previous button area (left third)
                            Button(
                                "Back", systemImage: "backward.fill", action: { npm.prevTrack() }
                            )
                            .labelStyle(.iconOnly)
                            .buttonStyle(PlainButtonStyle())
                            // Play/pause button area (middle third)
                            Button(
                                npm.currentEntry.isPlaying ? "Pause" : "Play",
                                systemImage: npm.currentEntry.isPlaying
                                    ? "pause.fill" : "play.fill",
                                action: {
                                    npm.playPause()
                                }
                            )
                            .labelStyle(.iconOnly)
                            .buttonStyle(PlainButtonStyle())
                            // Next button area (right third)
                            Button(
                                "Forward", systemImage: "forward.fill",
                                action: {
                                    npm.nextTrack()
                                }
                            )
                            .labelStyle(.iconOnly)
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 4)
                    }.padding(.bottom, 20)
                }
                .padding(.top, 4)
            } else if let widgetNPM = NowPlayingManager as? WidgetNowPlayingManager {
                // Widget version
                widgetTrackInfoView(entry: widgetNPM.currentEntry)
            }
        }
        .padding(.top, 20)
        .scaleEffect(0.9)
    }

    private func trackInfoView(entry: TuneStatusEntry) -> some View {
        // Album artwork
        VStack(alignment: .center) {
            if let artwork = entry.artworkImage {
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
            Text(entry.trackName)
                .font(.title2)
                .lineLimit(1)
            //                    .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.3))

            Text(entry.artistName)
                .font(.title3)
                .foregroundColor(.secondary)
                .lineLimit(1)
            //                    .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.3).opacity(0.8))

            Text(entry.albumName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            //                    .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.3).opacity(0.7))

            // Progress bar
            HStack {
                Text(formatTime(entry.currentTime))
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
                            .frame(
                                width: min(
                                    CGFloat(entry.progressPercentage) * geometry.size.width,
                                    geometry.size.width), height: 4
                            )
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .frame(height: 4)
                Text(formatTime(entry.duration))
                    .font(.caption)
                    .monospacedDigit()
            }
        }
    }

    private func widgetTrackInfoView(entry: TuneStatusEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Artwork image if available
            if let artwork = entry.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .cornerRadius(8)
            } else {
                // Placeholder if no artwork
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    )
            }

            // Track info
            Text(entry.trackName)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)

            Text(entry.artistName)
                .font(.title3)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(entry.albumName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)

            // Playback state indicator
            HStack {
                Circle()
                    .fill(entry.isPlaying ? Color.green : Color.red)
                    .frame(width: 10, height: 10)

                Text(entry.isPlaying ? "Playing" : "Paused")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(Date() - entry.currentTime, style: .timer)
                    .font(.caption)

            }
        }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct TuneStatusPreview: PreviewProvider {
    static var previews: some View {
        let npmanager = NowPlayingManager()
        return TuneStatusView(NowPlayingManager: npmanager).frame(width: 320, height: 480)
    }
}
