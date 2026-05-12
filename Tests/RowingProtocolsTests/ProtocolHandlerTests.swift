import XCTest
@testable import RowingProtocols

final class ProtocolHandlerTests: XCTestCase {

    // MARK: - ProtocolRegistry

    func testRegistryLookupByType() {
        let c2 = ProtocolRegistry.handler(for: .concept2)
        XCTAssertNotNil(c2)
        XCTAssertEqual(c2?.protocolType, .concept2)

        let ftms = ProtocolRegistry.handler(for: .ftms)
        XCTAssertNotNil(ftms)
        XCTAssertEqual(ftms?.protocolType, .ftms)
    }

    func testRegistryLookupByTypeReturnsNilForWatchCoreMotion() {
        XCTAssertNil(ProtocolRegistry.handler(for: .watchCoreMotion))
    }

    func testRegistryLookupByServiceUUID() {
        let c2 = ProtocolRegistry.handler(forServiceUUID: C2UUIDs.rowingService)
        XCTAssertEqual(c2?.protocolType, .concept2)

        let ftms = ProtocolRegistry.handler(forServiceUUID: FTMSUUIDs.fitnessMachineService)
        XCTAssertEqual(ftms?.protocolType, .ftms)
    }

    func testRegistryLookupByServiceUUIDIsCaseInsensitive() {
        let handler = ProtocolRegistry.handler(forServiceUUID: C2UUIDs.rowingService.lowercased())
        XCTAssertEqual(handler?.protocolType, .concept2)
    }

    func testRegistryLookupByUnknownServiceUUIDReturnsNil() {
        XCTAssertNil(ProtocolRegistry.handler(forServiceUUID: "0000FFFF-0000-1000-8000-00805F9B34FB"))
    }

    func testScanServiceUUIDsContainsBothProtocols() {
        let uuids = ProtocolRegistry.scanServiceUUIDs
        XCTAssertTrue(uuids.contains(C2UUIDs.rowingService))
        XCTAssertTrue(uuids.contains(FTMSUUIDs.fitnessMachineService))
    }

    // MARK: - C2ProtocolHandler

    func testC2ServiceDefinition() {
        let handler = C2ProtocolHandler()
        let def = handler.serviceDefinition
        XCTAssertEqual(def.serviceUUID, C2UUIDs.rowingService)
        XCTAssertEqual(def.characteristics.count, 5)
        XCTAssertEqual(def.notifyCharacteristicUUIDs.count, 4)

        let writable = def.characteristics.filter(\.isWritable)
        XCTAssertEqual(writable.count, 1)
        XCTAssertEqual(writable.first?.uuid, C2UUIDs.sampleRate)
    }

    func testC2DecodeGeneralStatus() {
        let snapshot = RowingSnapshot(
            elapsedTime: 100.0, distance: 250.0, dragFactor: 110,
            workoutState: .rowing, rowingState: .active, strokeState: .driving
        )
        let data = C2GeneralStatus.encode(snapshot)
        let handler = C2ProtocolHandler()
        let decoded = handler.decode(characteristicUUID: C2UUIDs.generalStatus, data: data)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.workoutState, .rowing)
        XCTAssertEqual(decoded?.dragFactor, 110)
    }

    func testC2DecodeAdditionalStatus1() {
        let snapshot = RowingSnapshot(elapsedTime: 60.0, strokeRate: 28, pace: 105.0, heartRate: 160)
        let data = C2AdditionalStatus1.encode(snapshot)
        let handler = C2ProtocolHandler()
        let decoded = handler.decode(characteristicUUID: C2UUIDs.additionalStatus1, data: data)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.strokeRate, 28)
        XCTAssertEqual(decoded?.heartRate, 160)
    }

    func testC2DecodeStrokeData() {
        let snapshot = RowingSnapshot(elapsedTime: 90.0, distance: 300.0, strokeCount: 45, workPerStroke: 220.0)
        let data = C2StrokeData.encode(snapshot)
        let handler = C2ProtocolHandler()
        let decoded = handler.decode(characteristicUUID: C2UUIDs.strokeData, data: data)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.strokeCount, 45)
    }

    func testC2DecodeAdditionalStrokeData() {
        let snapshot = RowingSnapshot(elapsedTime: 120.0, strokeCount: 60, power: 210, caloriesPerHour: 850)
        let data = C2AdditionalStrokeData.encode(snapshot)
        let handler = C2ProtocolHandler()
        let decoded = handler.decode(characteristicUUID: C2UUIDs.additionalStrokeData, data: data)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.power, 210)
    }

    func testC2DecodeUnknownCharacteristicReturnsNil() {
        let handler = C2ProtocolHandler()
        XCTAssertNil(handler.decode(characteristicUUID: "00001234-0000-0000-0000-000000000000", data: Data([0x00])))
    }

    func testC2EncodeProducesNonEmptyData() {
        let snapshot = RowingSnapshot(elapsedTime: 50.0, distance: 100.0)
        let handler = C2ProtocolHandler()
        for uuid in [C2UUIDs.generalStatus, C2UUIDs.additionalStatus1, C2UUIDs.strokeData, C2UUIDs.additionalStrokeData] {
            XCTAssertFalse(handler.encode(snapshot: snapshot, characteristicUUID: uuid).isEmpty)
        }
    }

    func testC2EncodeUnknownCharacteristicReturnsEmptyData() {
        let handler = C2ProtocolHandler()
        XCTAssertTrue(handler.encode(snapshot: RowingSnapshot(), characteristicUUID: "UNKNOWN").isEmpty)
    }

    // MARK: - FTMSProtocolHandler

    func testFTMSServiceDefinition() {
        let handler = FTMSProtocolHandler()
        let def = handler.serviceDefinition
        XCTAssertEqual(def.serviceUUID, FTMSUUIDs.fitnessMachineService)
        XCTAssertEqual(def.characteristics.count, 1)
        XCTAssertEqual(def.notifyCharacteristicUUIDs.count, 1)
        XCTAssertEqual(def.characteristics.first?.uuid, FTMSUUIDs.rowerData)
    }

    func testFTMSDecodeRowerData() {
        let snapshot = RowingSnapshot(elapsedTime: 300, distance: 1500, strokeRate: 24, strokeCount: 120, power: 180)
        let data = FTMSRowerData.encode(snapshot)
        let handler = FTMSProtocolHandler()
        let decoded = handler.decode(characteristicUUID: FTMSUUIDs.rowerData, data: data)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.strokeRate, 24)
        XCTAssertEqual(decoded?.power, 180)
    }

    func testFTMSDecodeUnknownCharacteristicReturnsNil() {
        let handler = FTMSProtocolHandler()
        XCTAssertNil(handler.decode(characteristicUUID: "UNKNOWN", data: Data([0x00])))
    }

    func testFTMSEncodeUnknownCharacteristicReturnsEmptyData() {
        let handler = FTMSProtocolHandler()
        XCTAssertTrue(handler.encode(snapshot: RowingSnapshot(), characteristicUUID: "UNKNOWN").isEmpty)
    }

    // MARK: - ServiceDefinition

    func testNotifyCharacteristicUUIDsFiltersCorrectly() {
        let def = ServiceDefinition(
            serviceUUID: "TEST",
            characteristics: [
                CharacteristicDefinition(uuid: "A", isNotify: true),
                CharacteristicDefinition(uuid: "B", isNotify: false, isWritable: true),
                CharacteristicDefinition(uuid: "C", isNotify: true),
            ]
        )
        XCTAssertEqual(def.notifyCharacteristicUUIDs, ["A", "C"])
    }
}
