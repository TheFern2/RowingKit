import XCTest
@testable import RowingProtocols

final class FTMSRoundTripTests: XCTestCase {
    func testBasicFieldsRoundTrip() {
        let original = RowingSnapshot(
            elapsedTime: 300,
            distance: 1500,
            strokeRate: 24,
            strokeCount: 120,
            pace: 120,
            power: 180,
            heartRate: 155,
            calories: 95,
            caloriesPerHour: 720,
            caloriesPerMinute: 12
        )
        let data = FTMSRowerData.encode(original)
        let decoded = FTMSRowerData.decode(data)
        XCTAssertEqual(decoded.strokeRate, 24)
        XCTAssertEqual(decoded.strokeCount, 120)
        XCTAssertEqual(decoded.distance, 1500)
        XCTAssertEqual(decoded.pace, 120)
        XCTAssertEqual(decoded.power, 180)
        XCTAssertEqual(decoded.heartRate, 155)
        XCTAssertEqual(decoded.calories, 95)
        XCTAssertEqual(decoded.elapsedTime, 300)
    }

    func testEmptySnapshotProducesMinimalPacket() {
        let original = RowingSnapshot()
        let data = FTMSRowerData.encode(original)
        XCTAssertEqual(data.count, 2)
        let decoded = FTMSRowerData.decode(data)
        XCTAssertNil(decoded.strokeRate)
        XCTAssertNil(decoded.distance)
    }

    func testInvertedBit0Behavior() {
        let withStroke = RowingSnapshot(strokeRate: 22, strokeCount: 50)
        let data = FTMSRowerData.encode(withStroke)
        let flags = UInt16(data[0]) | (UInt16(data[1]) << 8)
        XCTAssertEqual(flags & 0x0001, 0) // bit 0 is 0 = present
    }
}
