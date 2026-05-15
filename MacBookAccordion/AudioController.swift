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
        setSounding(false)
        accordionEngine.stop()
        isReady = false
    }

    func setSounding(_ isSounding: Bool) {
        guard self.isSounding != isSounding else { return }
        self.isSounding = isSounding
        if !isSounding {
            accordionEngine.mute()
        }
    }
    
    func feed(angle: Double, velocity: Double) {
        guard isReady else { return }
        accordionEngine.update(angle: angle, velocity: velocity, isGateOpen: isSounding)
    }
    
    // MARK: Private
    
    var activeEngine: any AudioEngineProtocol { accordionEngine }
}
