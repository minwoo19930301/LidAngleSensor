//
//  MenuBarView.swift
//  LidAngleSensor
//
//  Created by Sam on 2026-03-22.
//

import SwiftUI

struct MenuBarView: View {
    @Environment(\.lidAngleSensor) private var sensor
    @Environment(\.audioController) private var audioController
    
    var body: some View {
        if !sensor.isAvailable {
            Text("Accordion Unavailable")
        }
        
        Section {
            Text("MacBook Accordion")
            Text("Note: \(audioController.accordionEngine.noteName)")
            Text(audioController.isSounding ? "Playing" : "Ready")
        }
        .disabled(!sensor.isAvailable)
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
