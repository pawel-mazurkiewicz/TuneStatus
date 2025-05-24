//
//  SettingsView.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 24/05/2025.
//

import SwiftUI
import ServiceManagement

// MARK: - UserDefaults Keys
private enum UserDefaultsKeys {
    static let launchAtLogin = "launchAtLogin"
    static let showArtistInMenuBar = "showArtistInMenuBar"
    static let showAlbumInMenuBar = "showAlbumInMenuBar"
}

// MARK: - UserDefaults Extensions (Swift 6 Style)
extension UserDefaults {
    @available(iOS 13.0, macOS 10.15, *)
    var showArtistInMenuBar: Bool {
        get { bool(forKey: UserDefaultsKeys.showArtistInMenuBar) }
        set { set(newValue, forKey: UserDefaultsKeys.showArtistInMenuBar) }
    }
    
    @available(iOS 13.0, macOS 10.15, *)
    var showAlbumInMenuBar: Bool {
        get { bool(forKey: UserDefaultsKeys.showAlbumInMenuBar) }
        set { set(newValue, forKey: UserDefaultsKeys.showAlbumInMenuBar) }
    }
    
    @available(iOS 13.0, macOS 10.15, *)
    var launchAtLoginSetting: Bool {
        get { bool(forKey: UserDefaultsKeys.launchAtLogin) }
        set { set(newValue, forKey: UserDefaultsKeys.launchAtLogin) }
    }
}

struct SettingsView: View {
    let onDismiss: () -> Void
    
    @State private var launchAtLogin = false
    @State private var showArtistInMenuBar = true
    @State private var showAlbumInMenuBar = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Configure TuneStatus preferences")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Launch at Login Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Startup")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Launch at Login")
                            .font(.subheadline)
                        
                        Text("Automatically start TuneStatus when you log in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            setLaunchAtLogin(enabled: newValue)
                        }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            Divider()
            
            // Menu Bar Display Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Menu Bar Display")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    // Show Artist Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Show Artist Name")
                                .font(.subheadline)
                            
                            Text("Display artist name along with track name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $showArtistInMenuBar)
                            .onChange(of: showArtistInMenuBar) { newValue in
                                UserDefaults.standard.showArtistInMenuBar = newValue
                                // Notify the status bar controller about the change
                                NotificationCenter.default.post(
                                    name: .menuBarDisplaySettingsChanged,
                                    object: nil
                                )
                            }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Show Album Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Show Album Name")
                                .font(.subheadline)
                            
                            Text("Display album name in menu bar (requires artist to be enabled)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $showAlbumInMenuBar)
                            .disabled(!showArtistInMenuBar) // Disable if artist is not shown
                            .onChange(of: showAlbumInMenuBar) { newValue in
                                UserDefaults.standard.showAlbumInMenuBar = newValue
                                // Notify the status bar controller about the change
                                NotificationCenter.default.post(
                                    name: .menuBarDisplaySettingsChanged,
                                    object: nil
                                )
                            }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .opacity(showArtistInMenuBar ? 1.0 : 0.6) // Visual feedback when disabled
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack {
                Spacer()
                
                Button("Done") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 450, height: 500) // Increased height to accommodate new settings
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadCurrentSettings() {
        // Load launch at login state
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            launchAtLogin = UserDefaults.standard.launchAtLoginSetting
        }
        
        // Load menu bar display settings with default values
        showArtistInMenuBar = UserDefaults.standard.object(forKey: UserDefaultsKeys.showArtistInMenuBar) as? Bool ?? true
        showAlbumInMenuBar = UserDefaults.standard.object(forKey: UserDefaultsKeys.showAlbumInMenuBar) as? Bool ?? false
        
        // If album is enabled but artist is disabled, disable album
        if showAlbumInMenuBar && !showArtistInMenuBar {
            showAlbumInMenuBar = false
            UserDefaults.standard.showAlbumInMenuBar = false
        }
    }
    
    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                // Store in UserDefaults as backup
                UserDefaults.standard.launchAtLoginSetting = enabled
            } catch {
                // Revert the toggle state on error
                launchAtLogin = !enabled
                alertMessage = "Failed to update launch at login setting: \(error.localizedDescription)"
                showingAlert = true
            }
        } else {
            // Fallback for older macOS versions
            UserDefaults.standard.launchAtLoginSetting = enabled
            launchAtLogin = enabled
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let menuBarDisplaySettingsChanged = Notification.Name("menuBarDisplaySettingsChanged")
}

#Preview {
    SettingsView(onDismiss: {})
} 