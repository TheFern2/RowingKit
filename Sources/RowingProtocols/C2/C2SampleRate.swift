import Foundation

public enum C2SampleRate: UInt8, Sendable {
    case sec1 = 0
    case ms500 = 1
    case ms250 = 2
    case ms100 = 3

    public var interval: TimeInterval {
        switch self {
        case .sec1: 1.0
        case .ms500: 0.5
        case .ms250: 0.25
        case .ms100: 0.1
        }
    }
}
