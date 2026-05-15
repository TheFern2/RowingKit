public protocol RowingDataProvider: AnyObject, Sendable {
    var id: String { get }
    var displayName: String { get }
    var protocolType: RowingProtocolType { get }
    var connectionState: ConnectionState { get }
    var hrmConnectionState: ConnectionState { get }
    var latestSnapshot: RowingSnapshot? { get }
    var snapshotStream: AsyncStream<RowingSnapshot> { get }
}
