import Foundation

public struct C2ProtocolHandler: RowingProtocolHandler {
    public let protocolType: RowingProtocolType = .concept2
    public let serviceUUID: String = C2UUIDs.rowingService

    public var serviceDefinition: ServiceDefinition {
        ServiceDefinition(
            serviceUUID: C2UUIDs.rowingService,
            characteristics: [
                CharacteristicDefinition(uuid: C2UUIDs.generalStatus, isNotify: true),
                CharacteristicDefinition(uuid: C2UUIDs.additionalStatus1, isNotify: true),
                CharacteristicDefinition(uuid: C2UUIDs.strokeData, isNotify: true),
                CharacteristicDefinition(uuid: C2UUIDs.additionalStrokeData, isNotify: true),
                CharacteristicDefinition(uuid: C2UUIDs.sampleRate, isNotify: false, isWritable: true),
            ]
        )
    }

    public init() {}

    public func decode(characteristicUUID: String, data: Data) -> RowingSnapshot? {
        switch characteristicUUID.uppercased() {
        case C2UUIDs.generalStatus.uppercased():
            C2GeneralStatus.decode(data)
        case C2UUIDs.additionalStatus1.uppercased():
            C2AdditionalStatus1.decode(data)
        case C2UUIDs.strokeData.uppercased():
            C2StrokeData.decode(data)
        case C2UUIDs.additionalStrokeData.uppercased():
            C2AdditionalStrokeData.decode(data)
        default:
            nil
        }
    }

    public func encode(snapshot: RowingSnapshot, characteristicUUID: String) -> Data {
        switch characteristicUUID.uppercased() {
        case C2UUIDs.generalStatus.uppercased():
            C2GeneralStatus.encode(snapshot)
        case C2UUIDs.additionalStatus1.uppercased():
            C2AdditionalStatus1.encode(snapshot)
        case C2UUIDs.strokeData.uppercased():
            C2StrokeData.encode(snapshot)
        case C2UUIDs.additionalStrokeData.uppercased():
            C2AdditionalStrokeData.encode(snapshot)
        default:
            Data()
        }
    }
}
