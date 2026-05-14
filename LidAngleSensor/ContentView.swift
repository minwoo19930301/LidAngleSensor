//
//  ContentView.swift
//  LidAngleSensor
//
//  Created by Sam on 2026-03-22.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.lidAngleSensor) private var sensor
    @Environment(\.audioController) private var audioController

    @State private var inspectorShown = true

    var body: some View {
        @Bindable var controller = audioController
        @Bindable var creak = audioController.creakEngine
        @Bindable var theremin = audioController.thereminEngine
        @Bindable var accordion = audioController.accordionEngine

        NavigationStack {
            VStack {
                if sensor.isAvailable {
                    Text("\(sensor.angle, format: .number)°")
                        .foregroundStyle(.blue)
                        .font(.system(size: 144, weight: .thin))
                        .tracking(-3)

                    Group {
                        Text("Velocity: \(String(format: "%+03d", Int(sensor.velocity.rounded()))) deg/s")
                        Text(sensor.status)
                    }
                    .foregroundStyle(.secondary)
                } else {
                    Text("Not Available")
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
            }
            .onChange(of: sensor.tick) {
                audioController.feed(angle: sensor.angle, velocity: sensor.velocity)
            }
            .toolbar {
                ToolbarItemGroup {
                    Button(
                        audioController.isPlaying ? "Stop" : "Play",
                        systemImage: audioController.isPlaying ? "stop" : "play"
                    ) {
                        audioController.toggle()
                    }
                    .symbolVariant(.fill)
                    .disabled(!sensor.isAvailable)
                    .keyboardShortcut(.space, modifiers: [])

                    Button {
                        inspectorShown.toggle()
                    } label: {
                        Label("Audio Controls", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .inspector(isPresented: $inspectorShown) {
                Form {
                    Section {
                        Picker("Audio Mode", selection: $controller.mode) {
                            ForEach(AudioMode.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }

                        switch audioController.mode {
                        case .accordion:
                            LabeledContent("Note", value: audioController.accordionEngine.noteName)
                            LabeledContent("Direction", value: audioController.accordionEngine.directionName)
                            LabeledContent("Bellows", value: audioController.accordionEngine.bellows, format: .number.precision(.fractionLength(2)))
                            LabeledContent("Volume", value: audioController.accordionEngine.volume, format: .number.precision(.fractionLength(2)))
                        case .creak:
                            LabeledContent("Gain", value: audioController.creakEngine.gain, format: .number.precision(.fractionLength(2)))
                            LabeledContent("Rate", value: audioController.creakEngine.rate, format: .number.precision(.fractionLength(2)))
                        case .theremin:
                            LabeledContent("Frequency", value: audioController.thereminEngine.frequency, format: .number.precision(.fractionLength(1)))
                            LabeledContent("Volume", value: audioController.thereminEngine.volume, format: .number.precision(.fractionLength(2)))
                        }
                    }

                    switch audioController.mode {
                    case .accordion:
                        Section("Bellows") {
                            ParameterSlider(label: "Full Volume", value: $accordion.velocityFull, range: 8...160, unit: "deg/s", fractionDigits: 0)
                            ParameterSlider(label: "Deadzone", value: $accordion.velocityDeadzone, range: 0...8, unit: "deg/s", fractionDigits: 1)
                            ParameterSlider(label: "Max Volume", value: $accordion.maxVolume, range: 0...1, fractionDigits: 2)
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
                    case .creak:
                        Section("Velocity") {
                            ParameterSlider(label: "Full Volume", value: $creak.velocityFull, range: 1...100, unit: "deg/s", fractionDigits: 0)
                            ParameterSlider(label: "Quiet", value: $creak.velocityQuiet, range: 10...300, unit: "deg/s", fractionDigits: 0)
                        }
                        Section("Pitch") {
                            ParameterSlider(label: "Min Rate", value: $creak.minRate, range: 0.5...1.0, unit: "×", fractionDigits: 2)
                            ParameterSlider(label: "Max Rate", value: $creak.maxRate, range: 1.0...2.0, unit: "×", fractionDigits: 2)
                        }
                        Section("Ramping") {
                            ParameterSlider(label: "Gain", value: $creak.gainRampMs, range: 10...500, unit: "ms", fractionDigits: 0)
                            ParameterSlider(label: "Rate", value: $creak.rateRampMs, range: 10...500, unit: "ms", fractionDigits: 0)
                        }
                    case .theremin:
                        Section("Frequency") {
                            ParameterSlider(label: "Min", value: $theremin.minFrequency, range: 55...880, unit: "Hz", fractionDigits: 0)
                            ParameterSlider(label: "Max", value: $theremin.maxFrequency, range: 110...2000, unit: "Hz", fractionDigits: 0)
                        }
                        Section("Volume") {
                            ParameterSlider(label: "Base", value: $theremin.baseVolume, range: 0...1, fractionDigits: 2)
                            ParameterSlider(label: "Velocity Boost", value: $theremin.velocityVolumeBoost, range: 0...1, fractionDigits: 2)
                        }
                        Section("Vibrato") {
                            ParameterSlider(label: "Rate", value: $theremin.vibratoFreq, range: 0...20, unit: "Hz", fractionDigits: 1)
                            ParameterSlider(label: "Depth", value: $theremin.vibratoDepth, range: 0...0.15, fractionDigits: 3)
                        }
                        Section("Ramping") {
                            ParameterSlider(label: "Frequency", value: $theremin.frequencyRampMs, range: 5...300, unit: "ms", fractionDigits: 0)
                            ParameterSlider(label: "Volume", value: $theremin.volumeRampMs, range: 5...300, unit: "ms", fractionDigits: 0)
                        }
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
}
