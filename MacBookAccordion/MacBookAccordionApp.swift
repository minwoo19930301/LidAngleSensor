//
//  MacBookAccordionApp.swift
//  MacBookAccordion
//
//  Created by Sam on 2026-03-22.
//

import SwiftUI

@main
struct MacBookAccordionApp: App {
    @State private var sensor = LidAngleReader()
    @State private var audioController = AudioController()
    
    var body: some Scene {
        Window("MacBook Accordion", id: "main") {
            ContentView()
                .environment(\.lidAngleReader, sensor)
                .environment(\.audioController, audioController)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Link(destination: URL(string: "https://github.com/minwoo19930301/macbook-accordion")!) {
                    Label("View Source", systemImage: "swift")
                }
            }
        }
        
        MenuBarExtra {
            MenuBarView()
                .environment(\.lidAngleReader, sensor)
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
