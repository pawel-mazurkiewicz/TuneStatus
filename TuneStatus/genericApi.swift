//
//  genericApi.swift
//  TuneStatus
//
//  Created by Paweł Mazurkiewicz on 04/03/2025.
//

import Foundation
import Cocoa
import Carbon.HIToolbox

func sendMediaKey(key: UInt32) {
    // This nested function creates and posts a key event.
    func doKey(down: Bool) {
        // For key down events, modifier flags are 0xa00; for key up events, 0xb00.
        let flagsValue: UInt32 = down ? 0xa00 : 0xb00
        let flags = NSEvent.ModifierFlags(rawValue: UInt(truncatingIfNeeded: flagsValue))
        // Combine the key and flags into the data1 parameter.
        let data1 = Int((key << 16) | flagsValue)
        
        // Create a system-defined event.
        if let event = NSEvent.otherEvent(with: .systemDefined,
                                          location: .zero,
                                          modifierFlags: flags,
                                          timestamp: 0,
                                          windowNumber: 0,
                                          context: nil,
                                          subtype: 8,
                                          data1: data1,
                                          data2: -1),
           let cgEvent = event.cgEvent {
            // Post the event to the HID event tap.
            cgEvent.post(tap: .cghidEventTap)
        }
    }
    // Send the key press and release.
    doKey(down: true)
    doKey(down: false)
}

// MARK: - Media Key Simulation
struct genericApi {
    static func pressPlayPauseKey() {
        sendMediaKey(key: UInt32(NX_KEYTYPE_PLAY))
    }
    
    static func pressNextTrackKey() {
        sendMediaKey(key: UInt32(NX_KEYTYPE_NEXT))
    }
    
    static func pressPreviousTrackKey() {
        sendMediaKey(key: UInt32(NX_KEYTYPE_PREVIOUS))
    }
    
    static func executeScript(phrase: String? = "", bespokeScript: String? = nil, osaString: String? = "") -> String {
        var output = ""
        var script: NSAppleScript? = NSAppleScript(source: "")
        if let bespokeScript = bespokeScript {
            script = NSAppleScript(source: bespokeScript)
        } else if let phrase = phrase {
            script = NSAppleScript(source: "\(osaString ?? "") \(phrase)")
        }
        var errorInfo: NSDictionary?
        let descriptor = script?.executeAndReturnError(&errorInfo)
        if let descriptorString = descriptor?.stringValue {
            output = descriptorString
        }
        return output
    }
}

