import SwiftUI

@Observable
final class TourManager {
    private let storagePrefix = "weekbite_tour_seen_"
    private let welcomeKey = "weekbite_welcome_seen"

    var isActive: Bool = false
    var showWelcome: Bool = false
    var steps: [TourStep] = []
    var currentIndex: Int = 0
    private var currentTourId: String = ""

    var currentStep: TourStep? {
        guard isActive, currentIndex >= 0, currentIndex < steps.count else { return nil }
        return steps[currentIndex]
    }

    var totalSteps: Int { steps.count }

    // MARK: - Welcome

    func tryShowWelcome() {
        if UserDefaults.standard.bool(forKey: welcomeKey) { return }
        showWelcome = true
    }

    func dismissWelcome() {
        UserDefaults.standard.set(true, forKey: welcomeKey)
        showWelcome = false
    }

    // MARK: - Tour

    func hasSeenTour(_ tourId: String) -> Bool {
        UserDefaults.standard.bool(forKey: storagePrefix + tourId)
    }

    func markSeen(_ tourId: String) {
        UserDefaults.standard.set(true, forKey: storagePrefix + tourId)
    }

    func startTour(_ tourId: String, steps: [TourStep]) {
        guard !hasSeenTour(tourId), !isActive, !steps.isEmpty else { return }
        self.steps = steps
        self.currentIndex = 0
        self.currentTourId = tourId
        self.isActive = true
    }

    func nextStep() {
        let next = currentIndex + 1
        if next >= steps.count {
            endTour()
        } else {
            currentIndex = next
        }
    }

    func endTour() {
        isActive = false
        if !currentTourId.isEmpty {
            markSeen(currentTourId)
        }
        currentTourId = ""
        steps = []
        currentIndex = 0
    }

    func resetAllTours() {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(storagePrefix) }
        for key in keys {
            defaults.removeObject(forKey: key)
        }
    }
}

// MARK: - Anchor PreferenceKey

struct TourAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func tourAnchor(_ id: String) -> some View {
        if id.isEmpty {
            return AnyView(self)
        }
        return AnyView(
            self.anchorPreference(key: TourAnchorKey.self, value: .bounds) { [id: $0] }
        )
    }
}
