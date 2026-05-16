//
//  ContentView.swift
//  MacBookAccordion
//
//  Created by Sam on 2026-03-22.
//

import SwiftUI
import AppKit
import ApplicationServices

struct ContentView: View {
    @Environment(\.lidAngleReader) private var sensor
    @Environment(\.audioController) private var audioController

    @State private var inspectorShown = false
    @State private var localKeyMonitor: Any?
    @State private var globalKeyMonitor: Any?
    @State private var isGlobalKeyboardAccessEnabled = AXIsProcessTrusted()

    private static let spaceKeyCode: UInt16 = 49

    var body: some View {
        @Bindable var accordion = audioController.accordionEngine

        NavigationStack {
            VStack(spacing: 26) {
                if sensor.isAvailable {
                    VStack(spacing: 8) {
                        Text("MacBook Accordion")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(audioController.accordionEngine.noteName)
                            .font(.system(size: 138, weight: .thin, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(audioController.isSounding ? .green : (audioController.isSpaceHeld ? .orange : .blue))
                    }
                    
                    AccordionBellowsView(
                        pressure: audioController.accordionEngine.bellows,
                        isSounding: audioController.isSounding
                    )
                    .frame(width: 360, height: 92)
                    
                    HStack(spacing: 12) {
                        KeycapView(text: "Space")
                        Text(statusText)
                            .font(.headline)
                            .foregroundStyle(audioController.isSounding ? .green : (audioController.isSpaceHeld ? .orange : .secondary))
                    }
                    
                    HStack(spacing: 18) {
                        Label(audioController.accordionEngine.directionName, systemImage: "arrow.left.and.right")
                        Label(
                            "\(String(format: "%+03d", Int(sensor.velocity.rounded()))) deg/s",
                            systemImage: "wind"
                        )
                    }
                    .foregroundStyle(.secondary)
                } else {
                    Text("Accordion Unavailable")
                        .foregroundStyle(.red)
                        .font(.system(size: 56, weight: .light))

                    Text(sensor.status)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                        .padding(.top, 4)
                }
            }
            .monospacedDigit()
            .onAppear {
                sensor.start()
                audioController.start()
                installKeyMonitors()
            }
            .onDisappear {
                removeKeyMonitors()
                audioController.stop()
            }
            .onChange(of: sensor.tick) {
                audioController.feed(angle: sensor.angle, velocity: sensor.velocity)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                refreshGlobalKeyboardAccess(prompt: false)
            }
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        inspectorShown.toggle()
                    } label: {
                        Label("Tone Controls", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .inspector(isPresented: $inspectorShown) {
                Form {
                    Section("Status") {
                        LabeledContent("Note", value: audioController.accordionEngine.noteName)
                        LabeledContent("Direction", value: audioController.accordionEngine.directionName)
                        LabeledContent("Space", value: audioController.isSpaceHeld ? "Held" : "Up")
                        LabeledContent("Background Space", value: isGlobalKeyboardAccessEnabled ? "Enabled" : "Needs Accessibility")
                        LabeledContent("Last Played", value: audioController.lastTriggeredNoteName)
                        LabeledContent("Burst", value: audioController.accordionEngine.bellows, format: .number.precision(.fractionLength(2)))
                        LabeledContent("Volume", value: audioController.accordionEngine.volume, format: .number.precision(.fractionLength(2)))
                    }

                    if !isGlobalKeyboardAccessEnabled {
                        Section("Keyboard Access") {
                            Button("Open Accessibility Settings") {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                    NSWorkspace.shared.open(url)
                                }
                            }

                            Button("Check Again") {
                                refreshGlobalKeyboardAccess(prompt: false)
                            }
                        }
                    }

                    Section("Trigger") {
                        ParameterSlider(label: "Base Hit", value: $accordion.keyPressure, range: 0.1...1.0, fractionDigits: 2)
                        ParameterSlider(label: "Motion Boost", value: $accordion.velocityFull, range: 8...160, unit: "deg/s", fractionDigits: 0)
                        ParameterSlider(label: "Deadzone", value: $accordion.velocityDeadzone, range: 0...8, unit: "deg/s", fractionDigits: 1)
                        ParameterSlider(label: "Max Volume", value: $accordion.maxVolume, range: 0...1, fractionDigits: 2)
                        ParameterSlider(label: "Note Burst", value: $accordion.noteBurstMs, range: 80...900, unit: "ms", fractionDigits: 0)
                    }
                    Section("Reeds") {
                        ParameterSlider(label: "Detune", value: $accordion.detuneCents, range: 0...28, unit: "cents", fractionDigits: 1)
                        ParameterSlider(label: "Brightness", value: $accordion.brightness, range: 0...1, fractionDigits: 2)
                        ParameterSlider(label: "Bass Mix", value: $accordion.bassMix, range: 0...0.6, fractionDigits: 2)
                    }
                    Section("Musette") {
                        ParameterSlider(label: "Rate", value: $accordion.tremoloRate, range: 0...12, unit: "Hz", fractionDigits: 1)
                        ParameterSlider(label: "Depth", value: $accordion.tremoloDepth, range: 0...0.35, fractionDigits: 2)
                    }
                    Section("Ramping") {
                        ParameterSlider(label: "Note", value: $accordion.noteRampMs, range: 5...160, unit: "ms", fractionDigits: 0)
                        ParameterSlider(label: "Volume", value: $accordion.volumeRampMs, range: 10...500, unit: "ms", fractionDigits: 0)
                    }

                    Section {
                        Button("Reset to Defaults") {
                            audioController.activeEngine.resetToDefaults()
                        }
                    }
                }
                .inspectorColumnWidth(min: 220, ideal: 260, max: 340)
                .disabled(!sensor.isAvailable)
            }
        }
        .frame(minWidth: 800, minHeight: 400)
        .frame(idealWidth: 900, idealHeight: 667)
    }

    private func installKeyMonitors() {
        guard localKeyMonitor == nil, globalKeyMonitor == nil else { return }

        refreshGlobalKeyboardAccess(prompt: true)

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
            guard event.keyCode == Self.spaceKeyCode else { return event }
            handleSpaceKey(isDown: event.type == .keyDown, isRepeat: event.isARepeat)
            return nil
        }

        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
            guard event.keyCode == Self.spaceKeyCode else { return }
            let isDown = event.type == .keyDown
            let isRepeat = event.isARepeat

            Task { @MainActor in
                handleSpaceKey(isDown: isDown, isRepeat: isRepeat)
            }
        }
    }

    private func removeKeyMonitors() {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }

        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
            self.globalKeyMonitor = nil
        }

        audioController.setSpaceHeld(false)
    }

    private func handleSpaceKey(isDown: Bool, isRepeat: Bool) {
        if isDown, isRepeat {
            return
        }
        audioController.setSpaceHeld(isDown)
    }

    @discardableResult
    private func refreshGlobalKeyboardAccess(prompt: Bool) -> Bool {
        let isTrusted: Bool
        if prompt {
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            isTrusted = AXIsProcessTrustedWithOptions(options)
        } else {
            isTrusted = AXIsProcessTrusted()
        }

        isGlobalKeyboardAccessEnabled = isTrusted
        return isTrusted
    }

    private var statusText: String {
        if audioController.isSounding {
            return "Note changed"
        }
        if audioController.isSpaceHeld {
            return "Move lid to trigger"
        }
        return "Hold Space, then move"
    }
}

private struct AccordionBellowsView: View {
    let pressure: Double
    let isSounding: Bool

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(isSounding ? 0.9 : 0.45))
                .frame(width: 66)

            ZStack {
                ForEach(0..<9, id: \.self) { index in
                    let x = Double(index - 4) * 24.0
                    Rectangle()
                        .fill(.secondary.opacity(0.35 + pressure * 0.45))
                        .frame(width: 5)
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? 13 : -13))
                        .offset(x: x)
                }
            }
            .frame(maxWidth: .infinity)
            .background(.quaternary.opacity(0.7))

            RoundedRectangle(cornerRadius: 8)
                .fill(.green.opacity(isSounding ? 0.9 : 0.45))
                .frame(width: 66)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.secondary.opacity(0.35), lineWidth: 1)
        }
        .animation(.easeOut(duration: 0.12), value: pressure)
        .animation(.easeOut(duration: 0.12), value: isSounding)
    }
}

private struct KeycapView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.headline.monospaced())
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(.secondary.opacity(0.4), lineWidth: 1)
            }
    }
}
