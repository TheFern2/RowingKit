import Foundation
import RowingProtocols

public struct BLEConfiguration: Sendable {
    public var restoreIdentifier: String?
    public var scanDuplicates: Bool
    public var connectionTimeout: TimeInterval
    public var c2SampleRate: C2SampleRate

    public static let `default` = BLEConfiguration(
        restoreIdentifier: nil,
        scanDuplicates: false,
        connectionTimeout: 10.0,
        c2SampleRate: .ms500
    )

    public init(
        restoreIdentifier: String? = nil,
        scanDuplicates: Bool = false,
        connectionTimeout: TimeInterval = 10.0,
        c2SampleRate: C2SampleRate = .ms500
    ) {
        self.restoreIdentifier = restoreIdentifier
        self.scanDuplicates = scanDuplicates
        self.connectionTimeout = connectionTimeout
        self.c2SampleRate = c2SampleRate
    }
}
