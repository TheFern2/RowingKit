import XCTest
@testable import RowingBLE
import RowingProtocols

final class RowingBLETests: XCTestCase {
    func testPeripheralInitializesWithProtocolType() {
        let peripheral = RowingPeripheral(protocolType: .concept2)
        XCTAssertEqual(peripheral.protocolType, .concept2)
        XCTAssertFalse(peripheral.isAdvertising)
        XCTAssertEqual(peripheral.subscribedCentrals, 0)
    }

    func testCentralInitializesClean() {
        let central = RowingCentral()
        XCTAssertTrue(central.discoveredRowers.isEmpty)
        XCTAssertFalse(central.isScanning)
    }
}
