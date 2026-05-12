import Foundation

public struct CharacteristicDefinition: Sendable {
    public let uuid: String
    public let isNotify: Bool
    public let isWritable: Bool

    public init(uuid: String, isNotify: Bool, isWritable: Bool = false) {
        self.uuid = uuid
        self.isNotify = isNotify
        self.isWritable = isWritable
    }
}

public struct ServiceDefinition: Sendable {
    public let serviceUUID: String
    public let characteristics: [CharacteristicDefinition]

    public init(serviceUUID: String, characteristics: [CharacteristicDefinition]) {
        self.serviceUUID = serviceUUID
        self.characteristics = characteristics
    }

    public var notifyCharacteristicUUIDs: [String] {
        characteristics.filter(\.isNotify).map(\.uuid)
    }
}

public protocol RowingProtocolHandler: Sendable {
    var protocolType: RowingProtocolType { get }
    var serviceUUID: String { get }
    var serviceDefinition: ServiceDefinition { get }

    func decode(characteristicUUID: String, data: Data) -> RowingSnapshot?
    func encode(snapshot: RowingSnapshot, characteristicUUID: String) -> Data
}
