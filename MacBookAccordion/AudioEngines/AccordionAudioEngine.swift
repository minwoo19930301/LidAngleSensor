//
//  AccordionAudioEngine.swift
//  MacBookAccordion
//
//  Created by Codex on 2026-05-14.
//

import AVFoundation

@Observable
final class AccordionAudioEngine: AudioEngineProtocol {
    private(set) var isRunning = false
    private(set) var frequency = 261.63
    private(set) var volume = Double.zero
    private(set) var bellows = Double.zero
    private(set) var noteName = "C4"
    private(set) var directionName = "Pull"

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?

    // MARK: Audio-Thread State

    @ObservationIgnored nonisolated(unsafe) private var renderFrequency = 261.63
    @ObservationIgnored nonisolated(unsafe) private var renderBassFrequency = 130.81
    @ObservationIgnored nonisolated(unsafe) private var renderVolume = Double.zero
    @ObservationIgnored nonisolated(unsafe) private var renderDetuneCents = 11.0
    @ObservationIgnored nonisolated(unsafe) private var renderTremoloRate = 5.2
    @ObservationIgnored nonisolated(unsafe) private var renderTremoloDepth = 0.18
    @ObservationIgnored nonisolated(unsafe) private var renderBrightness = 0.58
    @ObservationIgnored nonisolated(unsafe) private var renderBassMix = 0.22
    @ObservationIgnored nonisolated(unsafe) private var renderPushPullTone = 1.0
    @ObservationIgnored nonisolated(unsafe) private var reedPhaseA = Double.zero
    @ObservationIgnored nonisolated(unsafe) private var reedPhaseB = Double.zero
    @ObservationIgnored nonisolated(unsafe) private var reedPhaseC = Double.zero
    @ObservationIgnored nonisolated(unsafe) private var bassPhase = Double.zero
    @ObservationIgnored nonisolated(unsafe) private var tremoloPhase = Double.zero

    // MARK: Ramping State

    private var targetFrequency = 261.63
    private var targetBassFrequency = 130.81
    private var targetVolume = Double.zero
    private var targetPushPullTone = 1.0
    private var lastRampTime: TimeInterval = 0

    // MARK: Parameters

    var maxVolume = 0.82
    var keyPressure = 0.62
    var velocityFull = 48.0
    var velocityDeadzone = 1.5
    var detuneCents = 11.0
    var tremoloRate = 5.2
    var tremoloDepth = 0.18
    var brightness = 0.58
    var bassMix = 0.22
    var noteRampMs = 24.0
    var volumeRampMs = 95.0

    private static let minAngle = 7.0
    private static let maxAngle = 135.0
    private static let scaleMidi = [
        48, 50, 52, 53, 55, 57, 59,
        60, 62, 64, 65, 67, 69, 71,
        72, 74, 76, 77, 79
    ]
    nonisolated private static let sampleRate = 44100.0

    // MARK: Lifecycle

    init() {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Self.sampleRate,
            channels: 1,
            interleaved: false
        ) else { return }

        let renderBlock: AVAudioSourceNodeRenderBlock = { [weak self] _, _, frameCount, bufferList in
            guard let self else { return noErr }
            return self.render(frameCount: frameCount, bufferList: bufferList)
        }

        sourceNode = AVAudioSourceNode(format: format, renderBlock: renderBlock)

        guard let sourceNode else { return }
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
    }

    // MARK: Control

    func start() {
        guard !isRunning else { return }
        try? engine.start()
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        engine.stop()
        isRunning = false
        mute()
    }

    func mute() {
        targetVolume = 0
        volume = 0
        bellows = 0
        renderVolume = 0
    }

    // MARK: Reset

    func resetToDefaults() {
        maxVolume = 0.82
        keyPressure = 0.62
        velocityFull = 48.0
        velocityDeadzone = 1.5
        detuneCents = 11.0
        tremoloRate = 5.2
        tremoloDepth = 0.18
        brightness = 0.58
        bassMix = 0.22
        noteRampMs = 24.0
        volumeRampMs = 95.0
    }

    // MARK: Parameter Update

    func update(angle: Double, velocity: Double, isGateOpen: Bool) {
        let normalizedAngle = min(1, max(0, (angle - Self.minAngle) / (Self.maxAngle - Self.minAngle)))
        let noteIndex = min(Self.scaleMidi.count - 1, max(0, Int((normalizedAngle * Double(Self.scaleMidi.count - 1)).rounded())))
        let midi = Self.scaleMidi[noteIndex]
        targetFrequency = Self.frequency(forMIDINote: midi)
        targetBassFrequency = Self.frequency(forMIDINote: midi - 12)
        noteName = Self.noteName(forMIDINote: midi)

        let speed = abs(velocity)
        if !isGateOpen {
            bellows = 0
            targetVolume = 0
        } else {
            let t = speed <= velocityDeadzone
                ? 0
                : min(1, max(0, (speed - velocityDeadzone) / max(1, velocityFull - velocityDeadzone)))
            let shaped = t * t * (3 - 2 * t)
            bellows = min(1, keyPressure + shaped * (1 - keyPressure))
            targetVolume = bellows * maxVolume
        }

        if velocity < -velocityDeadzone {
            directionName = "Push"
            targetPushPullTone = -1.0
        } else if velocity > velocityDeadzone {
            directionName = "Pull"
            targetPushPullTone = 1.0
        }

        ramp()
    }

    private func ramp() {
        let now = CACurrentMediaTime()
        let dt = lastRampTime == 0 ? 0.016 : now - lastRampTime
        lastRampTime = now

        frequency = frequency.ramped(toward: targetFrequency, dt: dt, tauMs: noteRampMs)
        volume = volume.ramped(toward: targetVolume, dt: dt, tauMs: volumeRampMs)

        renderFrequency = frequency
        renderBassFrequency = renderBassFrequency.ramped(toward: targetBassFrequency, dt: dt, tauMs: noteRampMs)
        renderVolume = volume
        renderDetuneCents = detuneCents
        renderTremoloRate = tremoloRate
        renderTremoloDepth = tremoloDepth
        renderBrightness = brightness
        renderBassMix = bassMix
        renderPushPullTone = renderPushPullTone.ramped(toward: targetPushPullTone, dt: dt, tauMs: 45.0)
    }

    // MARK: Render

    nonisolated private func render(
        frameCount: AVAudioFrameCount,
        bufferList: UnsafeMutablePointer<AudioBufferList>
    ) -> OSStatus {
        let output = bufferList.pointee.mBuffers.mData!.assumingMemoryBound(to: Float.self)
        let twoPi = 2.0 * Double.pi
        let baseFrequency = renderFrequency
        let bassFrequency = renderBassFrequency
        let volume = renderVolume
        let detuneRatio = pow(2.0, renderDetuneCents / 1200.0)
        let inverseDetuneRatio = pow(2.0, -renderDetuneCents / 1200.0)
        let tremoloIncrement = twoPi * renderTremoloRate / Self.sampleRate
        let brightness = renderBrightness
        let bassMix = renderBassMix
        let pushPullTone = renderPushPullTone

        for frame in 0..<Int(frameCount) {
            let tremolo = 1.0 + sin(tremoloPhase) * renderTremoloDepth
            let pushPullBrightness = min(1, max(0, brightness + pushPullTone * 0.05))

            let reedA = Self.reedWave(phase: reedPhaseA, brightness: pushPullBrightness)
            let reedB = Self.reedWave(phase: reedPhaseB + 0.22, brightness: brightness) * 0.72
            let reedC = Self.reedWave(phase: reedPhaseC + 0.41, brightness: max(0, brightness - 0.10)) * 0.54
            let bass = Self.reedWave(phase: bassPhase, brightness: max(0, brightness - 0.18)) * bassMix

            let mixed = (reedA + reedB + reedC + bass) / (2.26 + bassMix)
            let compressed = tanh(mixed * 1.8)
            output[frame] = Float(compressed * volume * tremolo * 0.55)

            reedPhaseA += twoPi * baseFrequency / Self.sampleRate
            reedPhaseB += twoPi * baseFrequency * detuneRatio / Self.sampleRate
            reedPhaseC += twoPi * baseFrequency * inverseDetuneRatio / Self.sampleRate
            bassPhase += twoPi * bassFrequency / Self.sampleRate
            tremoloPhase += tremoloIncrement

            if reedPhaseA >= twoPi { reedPhaseA -= twoPi }
            if reedPhaseB >= twoPi { reedPhaseB -= twoPi }
            if reedPhaseC >= twoPi { reedPhaseC -= twoPi }
            if bassPhase >= twoPi { bassPhase -= twoPi }
            if tremoloPhase >= twoPi { tremoloPhase -= twoPi }
        }

        return noErr
    }

    nonisolated private static func reedWave(phase: Double, brightness: Double) -> Double {
        let first = sin(phase)
        let second = sin(phase * 2.0 + 0.15) * 0.42 * brightness
        let third = sin(phase * 3.0 - 0.28) * 0.23 * brightness
        let fifth = sin(phase * 5.0 + 0.35) * 0.10 * brightness
        return tanh((first + second + third + fifth) * 1.35)
    }

    private static func frequency(forMIDINote midi: Int) -> Double {
        440.0 * pow(2.0, (Double(midi) - 69.0) / 12.0)
    }

    private static func noteName(forMIDINote midi: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = midi / 12 - 1
        return "\(names[midi % 12])\(octave)"
    }
}
