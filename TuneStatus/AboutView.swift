//
//  AboutView.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 24/05/2025.
//

import SwiftUI

struct AboutView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with app icon and title
            VStack(spacing: 12) {
                // App Icon
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // App Name
                Text("TuneStatus")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Version Info
                VStack(spacing: 4) {
                    Text("Version 0.0.3 (15)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Menu Bar Music Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 20)
            
            Divider()
            
            // App Description
            VStack(alignment: .leading, spacing: 12) {
                Text("About TuneStatus")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("TuneStatus is a lightweight menu bar application that displays your currently playing music from Spotify, Apple Music, and other compatible music applications.")
                    
                    Text("Features:")
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("Real-time music information in your menu bar")
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("Scrolling text for long track names")
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("Playback controls and progress tracking")
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("Support for Spotify and Apple Music")
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("Desktop widget integration")
                        }
                    }
                    .font(.caption)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Developer Info
            VStack(spacing: 8) {
                Text("Developer")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Paweł Mazurkiewicz")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Links (if you want to add them)
                HStack(spacing: 16) {
                    Link("GitHub", destination: URL(string: "https://github.com/user/pawel-mazurkiewicz")!)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("Support", destination: URL(string: "mailto:pawel@chillaid.art")!)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            
            // Spacer()
            
            // Close Button
            Button("OK") {
                onDismiss()
            }
            .padding(.bottom, 20)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 400, height: 550)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    AboutView(onDismiss: {})
}
