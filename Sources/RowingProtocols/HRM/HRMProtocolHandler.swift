import Foundation

public struct HRMProtocolHandler: RowingProtocolHandler {
    public let protocolType: RowingProtocolType = .heartRateMonitor
    public let serviceUUID: String = CommonUUIDs.heartRate

    public var serviceDefinition: ServiceDefinition {
        ServiceDefinition(
            serviceUUID: CommonUUIDs.heartRate,
            characteristics: [
                CharacteristicDefinition(uuid: CommonUUIDs.heartRateMeasurement, isNotify: true),
            ]
        )
    }

    public init() {}

    public func decode(characteristicUUID: String, data: Data) -> RowingSnapshot? {
        switch characteristicUUID.uppercased() {
        case CommonUUIDs.heartRateMeasurement.uppercased():
            HRMHeartRateMeasurement.decode(data)
        default:
            nil
        }
    }

    public func encode(snapshot: RowingSnapshot, characteristicUUID: String) -> Data {
        switch characteristicUUID.uppercased() {
        case CommonUUIDs.heartRateMeasurement.uppercased():
            HRMHeartRateMeasurement.encode(snapshot)
        default:
            Data()
        }
    }
}
