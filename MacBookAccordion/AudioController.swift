//
//  AudioController.swift
//  MacBookAccordion
//
//  Created by Sam on 2026-03-22.
//

import SwiftUI

@MainActor
private struct AudioControllerKey: EnvironmentKey {
    static let defaultValue = AudioController()
}

extension EnvironmentValues {
    var audioController: AudioController {
        get { self[AudioControllerKey.self] }
        set { self[AudioControllerKey.self] = newValue }
    }
}

@MainActor
@Observable
final class AudioController {
    
    // MARK: Published State
    
    private(set) var isReady = false
    private(set) var isSounding = false
    private(set) var isGateOpen = false
    private(set) var lastTriggeredNoteName = "C4"

    private var currentNoteIndex: Int?
    
    // MARK: Engines
    
    let accordionEngine = AccordionAudioEngine()
    
    // MARK: Control
    
    func start() {
        guard !isReady else { return }
        accordionEngine.start()
        isReady = true
    }

    func stop() {
        guard isReady else { return }
        setGateOpen(false)
        accordionEngine.stop()
        isReady = false
    }

    func setGateOpen(_ isGateOpen: Bool) {
        guard self.isGateOpen != isGateOpen else { return }
        self.isGateOpen = isGateOpen
        if !isGateOpen {
            isSounding = false
            accordionEngine.mute()
        }
    }
    
    func feed(angle: Double, velocity: Double) {
        guard isReady else { return }

        let noteIndex = accordionEngine.noteIndex(forAngle: angle)
        let changedNote = currentNoteIndex.map { $0 != noteIndex } ?? false
        currentNoteIndex = noteIndex

        let shouldTrigger = isGateOpen && changedNote
        accordionEngine.update(angle: angle, velocity: velocity, trigger: shouldTrigger)

        if shouldTrigger {
            lastTriggeredNoteName = accordionEngine.noteName
        }
        isSounding = accordionEngine.isAudible
    }
    
    // MARK: Private
    
    var activeEngine: any AudioEngineProtocol { accordionEngine }
}
