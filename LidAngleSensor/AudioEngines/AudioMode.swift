//
//  AudioMode.swift
//  LidAngleSensor
//
//  Created by Sam on 2026-03-22.
//

enum AudioMode: String, CaseIterable, Identifiable {
    case accordion = "Accordion"
    case creak = "Creak"
    case theremin = "Theremin"
    var id: Self { self }
}
