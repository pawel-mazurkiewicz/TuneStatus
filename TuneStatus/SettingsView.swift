//
//  SettingsView.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 24/05/2025.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    let onDismiss: () -> Void
    
    @State private var launchAtLogin = false
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
            
            // Future settings can go here
            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Menu Bar Display")
                            .font(.subheadline)
                        
                        Text("Show track name and artist in menu bar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // This is always enabled for now, but could be made configurable
                    Toggle("", isOn: .constant(true))
                        .disabled(true)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
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
        .frame(width: 400, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadCurrentLaunchAtLoginState()
        }
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadCurrentLaunchAtLoginState() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            // Fallback for older macOS versions
            launchAtLogin = false
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
            } catch {
                // Revert the toggle state on error
                launchAtLogin = !enabled
                alertMessage = "Failed to update launch at login setting: \(error.localizedDescription)"
                showingAlert = true
            }
        } else {
            // Fallback for older macOS versions
            launchAtLogin = false
            alertMessage = "Launch at login requires macOS 13.0 or later"
            showingAlert = true
        }
    }
}

#Preview {
    SettingsView(onDismiss: {})
} 