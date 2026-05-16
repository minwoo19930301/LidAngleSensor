//
//  MenuBarView.swift
//  MacBookAccordion
//
//  Created by Sam on 2026-03-22.
//

import SwiftUI

struct MenuBarView: View {
    @Environment(\.lidAngleReader) private var sensor
    @Environment(\.ambientLightReader) private var lightSensor
    @Environment(\.audioController) private var audioController
    
    var body: some View {
        if !sensor.isAvailable {
            Text("Accordion Unavailable")
        }
        
        Section {
            Text("MacBook Accordion")
            Text("Note: \(audioController.accordionEngine.noteName)")
            Text(lightSensor.isCovered ? "Camera covered" : "Cover camera area")
            Text("Light: \(Int(lightSensor.lux.rounded())) lux")
            Text(audioController.isSounding ? "Note changed" : "Waiting for movement")
        }
        .disabled(!sensor.isAvailable || !lightSensor.isAvailable)
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
