//
//  LidAngleSensorApp.swift
//  LidAngleSensor
//
//  Created by Sam on 2026-03-22.
//

import SwiftUI

@main
struct LidAngleSensorApp: App {
    @State private var sensor = LidAngleSensor()
    @State private var audioController = AudioController()
    
    var body: some Scene {
        Window("MacBook Accordion", id: "main") {
            ContentView()
                .environment(\.lidAngleSensor, sensor)
                .environment(\.audioController, audioController)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Link(destination: URL(string: "https://github.com/minwoo19930301/LidAngleSensor")!) {
                    Label("View Source", systemImage: "swift")
                }
            }
        }
        
        MenuBarExtra {
            MenuBarView()
                .environment(\.lidAngleSensor, sensor)
                .environment(\.audioController, audioController)
        } label: {
            Image(systemName: "music.note")
            
            if sensor.isAvailable {
                Text(audioController.accordionEngine.noteName)
                    .monospacedDigit()
            }
        }
    }
}
