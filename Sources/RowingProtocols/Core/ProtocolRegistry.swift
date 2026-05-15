public enum ProtocolRegistry: Sendable {
    public static let handlers: [any RowingProtocolHandler] = [
        C2ProtocolHandler(),
        FTMSProtocolHandler(),
        HRMProtocolHandler(),
    ]

    public static func handler(for type: RowingProtocolType) -> (any RowingProtocolHandler)? {
        handlers.first { $0.protocolType == type }
    }

    public static func handler(forServiceUUID uuid: String) -> (any RowingProtocolHandler)? {
        handlers.first { $0.serviceUUID.uppercased() == uuid.uppercased() }
    }

    public static var scanServiceUUIDs: [String] {
        handlers.map(\.serviceUUID)
    }
}
