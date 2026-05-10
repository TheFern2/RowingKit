import XCTest
@testable import RowingProtocols

final class C2RoundTripTests: XCTestCase {
    func testGeneralStatusRoundTrip() {
        let original = RowingSnapshot(
            elapsedTime: 125.50,
            distance: 432.7,
            dragFactor: 120,
            workoutState: .rowing,
            rowingState: .active,
            strokeState: .driving,
            workoutType: .justRow
        )
        let data = C2GeneralStatus.encode(original)
        XCTAssertEqual(data.count, C2GeneralStatus.characteristicSize)
        let decoded = C2GeneralStatus.decode(data)
        XCTAssertEqual(decoded.elapsedTime!, 125.50, accuracy: 0.01)
        XCTAssertEqual(decoded.distance!, 432.7, accuracy: 0.1)
        XCTAssertEqual(decoded.workoutState, .rowing)
        XCTAssertEqual(decoded.rowingState, .active)
        XCTAssertEqual(decoded.strokeState, .driving)
        XCTAssertEqual(decoded.dragFactor, 120)
    }

    func testAdditionalStatus1RoundTrip() {
        let original = RowingSnapshot(
            elapsedTime: 60.0,
            strokeRate: 28,
            pace: 105.0,
            averagePace: 107.5,
            speed: 4.762,
            heartRate: 165
        )
        let data = C2AdditionalStatus1.encode(original)
        XCTAssertEqual(data.count, C2AdditionalStatus1.characteristicSize)
        let decoded = C2AdditionalStatus1.decode(data)
        XCTAssertEqual(decoded.strokeRate, 28)
        XCTAssertEqual(decoded.heartRate, 165)
        XCTAssertEqual(decoded.pace!, 105.0, accuracy: 0.01)
    }

    func testStrokeDataRoundTrip() {
        let original = RowingSnapshot(
            elapsedTime: 90.0,
            distance: 300.0,
            strokeCount: 45,
            driveLength: 1.42,
            driveTime: 0.85,
            recoveryTime: 1.30,
            strokeDistance: 8.5,
            peakDriveForce: 85.0,
            avgDriveForce: 62.0,
            workPerStroke: 220.0
        )
        let data = C2StrokeData.encode(original)
        XCTAssertEqual(data.count, C2StrokeData.characteristicSize)
        let decoded = C2StrokeData.decode(data)
        XCTAssertEqual(decoded.strokeCount, 45)
        XCTAssertEqual(decoded.driveLength!, 1.42, accuracy: 0.01)
        XCTAssertEqual(decoded.workPerStroke!, 220.0, accuracy: 0.1)
    }

    func testAdditionalStrokeDataRoundTrip() {
        let original = RowingSnapshot(
            elapsedTime: 120.0,
            strokeCount: 60,
            power: 210,
            caloriesPerHour: 850
        )
        let data = C2AdditionalStrokeData.encode(original)
        XCTAssertEqual(data.count, C2AdditionalStrokeData.characteristicSize)
        let decoded = C2AdditionalStrokeData.decode(data)
        XCTAssertEqual(decoded.power, 210)
        XCTAssertEqual(decoded.caloriesPerHour, 850)
        XCTAssertEqual(decoded.strokeCount, 60)
    }
}
