import Foundation

public struct FTMSProtocolHandler: RowingProtocolHandler {
    public let protocolType: RowingProtocolType = .ftms
    public let serviceUUID: String = FTMSUUIDs.fitnessMachineService

    public var serviceDefinition: ServiceDefinition {
        ServiceDefinition(
            serviceUUID: FTMSUUIDs.fitnessMachineService,
            characteristics: [
                CharacteristicDefinition(uuid: FTMSUUIDs.rowerData, isNotify: true),
            ]
        )
    }

    public init() {}

    public func decode(characteristicUUID: String, data: Data) -> RowingSnapshot? {
        switch characteristicUUID.uppercased() {
        case FTMSUUIDs.rowerData.uppercased():
            FTMSRowerData.decode(data)
        default:
            nil
        }
    }

    public func encode(snapshot: RowingSnapshot, characteristicUUID: String) -> Data {
        switch characteristicUUID.uppercased() {
        case FTMSUUIDs.rowerData.uppercased():
            FTMSRowerData.encode(snapshot)
        default:
            Data()
        }
    }
}
