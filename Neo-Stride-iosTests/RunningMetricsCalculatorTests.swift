import Foundation
import Testing
@testable import Neo_Stride_ios

struct RunningMetricsCalculatorTests {
    @Test func accumulatesDistanceWhenLocationPassesFilters() throws {
        var calculator = RunningMetricsCalculator()
        let start = Date(timeIntervalSince1970: 0)
        let second = Date(timeIntervalSince1970: 60)

        calculator.start(at: start)
        calculator.add(sample: RunningLocationSample(latitude: 37.5665, longitude: 126.9780, timestamp: start, horizontalAccuracy: 5, speed: 0))
        calculator.add(sample: RunningLocationSample(latitude: 37.5674, longitude: 126.9780, timestamp: second, horizontalAccuracy: 5, speed: 1.7))

        let summary = calculator.summary(at: second)

        #expect(summary.durationSeconds == 60)
        #expect(summary.distanceKilometers > 0.09)
        #expect(summary.distanceKilometers < 0.12)
        #expect(summary.paceMinutesPerKilometer > 0)
    }

    @Test func ignoresInaccurateTooFastAndTooSmallMovements() throws {
        var calculator = RunningMetricsCalculator()
        let start = Date(timeIntervalSince1970: 0)

        calculator.start(at: start)
        calculator.add(sample: RunningLocationSample(latitude: 37.5665, longitude: 126.9780, timestamp: start, horizontalAccuracy: 5, speed: 0))
        calculator.add(sample: RunningLocationSample(latitude: 37.5666, longitude: 126.9780, timestamp: start.addingTimeInterval(10), horizontalAccuracy: 50, speed: 1))
        calculator.add(sample: RunningLocationSample(latitude: 37.5680, longitude: 126.9780, timestamp: start.addingTimeInterval(20), horizontalAccuracy: 5, speed: 20))
        calculator.add(sample: RunningLocationSample(latitude: 37.56651, longitude: 126.9780, timestamp: start.addingTimeInterval(30), horizontalAccuracy: 5, speed: 1))

        let summary = calculator.summary(at: start.addingTimeInterval(30))

        #expect(summary.distanceKilometers == 0)
        #expect(summary.route.count == 1)
    }

    @Test func pauseDurationIsExcludedFromElapsedDuration() throws {
        var calculator = RunningMetricsCalculator()
        let start = Date(timeIntervalSince1970: 0)
        calculator.start(at: start)
        calculator.pause(at: start.addingTimeInterval(30))
        calculator.resume(at: start.addingTimeInterval(90))

        let summary = calculator.summary(at: start.addingTimeInterval(120))

        #expect(summary.durationSeconds == 60)
    }

    @Test func zeroDistancePaceIsZero() throws {
        var calculator = RunningMetricsCalculator()
        let start = Date(timeIntervalSince1970: 0)
        calculator.start(at: start)

        let summary = calculator.summary(at: start.addingTimeInterval(300))

        #expect(summary.distanceKilometers == 0)
        #expect(summary.paceMinutesPerKilometer == 0)
    }
}
