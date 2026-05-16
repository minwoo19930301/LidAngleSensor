//
//  AmbientLightReader.swift
//  MacBookAccordion
//
//  Created by Codex on 2026-05-16.
//

import IOKit
import SwiftUI

private struct AmbientLightReaderKey: EnvironmentKey {
    static let defaultValue = AmbientLightReader()
}

extension EnvironmentValues {
    var ambientLightReader: AmbientLightReader {
        get { self[AmbientLightReaderKey.self] }
        set { self[AmbientLightReaderKey.self] = newValue }
    }
}

@Observable
final class AmbientLightReader {
    private(set) var lux = Double.zero
    private(set) var isAvailable = false
    private(set) var isCovered = false
    private(set) var tick = UInt.zero

    var coverThreshold = 15.0 {
        didSet { updateCoveredState() }
    }

    var status: String {
        guard isAvailable else { return "Ambient light sensor unavailable" }
        return isCovered ? "Camera area covered" : "Cover camera area"
    }

    @ObservationIgnored nonisolated(unsafe) private var service: io_service_t = 0
    @ObservationIgnored nonisolated(unsafe) private var timer: Timer?

    private static let pollInterval = 1.0 / 20.0
    private static let currentLuxKey = "CurrentLux" as CFString
    private static let candidateServiceClasses = [
        "AppleSPUVD6286",
        "AppleSPUVD6287",
        "AppleTCS3490",
        "AppleALSColorSensor",
        "AppleSMCLMU",
    ]

    deinit {
        timer?.invalidate()
        timer = nil
        if service != 0 {
            IOObjectRelease(service)
        }
    }

    func start() {
        guard timer == nil else { return }
        if service == 0 {
            service = Self.findAmbientLightService()
            isAvailable = service != 0
        }

        poll()
        guard isAvailable else { return }
        timer = .scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard service != 0, let currentLux = Self.readLux(from: service) else {
            isAvailable = false
            isCovered = false
            return
        }

        lux = currentLux
        isAvailable = true
        updateCoveredState()
        tick &+= 1
    }

    private func updateCoveredState() {
        isCovered = isAvailable && lux <= coverThreshold
    }

    private static func findAmbientLightService() -> io_service_t {
        for className in candidateServiceClasses {
            guard let matching = IOServiceMatching(className) else { continue }
            let candidate = IOServiceGetMatchingService(kIOMainPortDefault, matching)
            guard candidate != 0 else { continue }

            if readLux(from: candidate) != nil {
                return candidate
            }

            IOObjectRelease(candidate)
        }

        return 0
    }

    private static func readLux(from service: io_service_t) -> Double? {
        guard let property = IORegistryEntryCreateCFProperty(
            service,
            currentLuxKey,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else { return nil }

        if let value = property as? NSNumber {
            return value.doubleValue
        }

        return nil
    }
}
