public enum WorkoutState: UInt8, Sendable, Codable {
    case waitToBegin = 0
    case rowing = 1
    case intervalRest = 3
    case end = 10
    case terminate = 11
}

public enum RowingState: UInt8, Sendable, Codable {
    case inactive = 0
    case active = 1
}

public enum StrokeState: UInt8, Sendable, Codable {
    case waitingMinSpeed = 0
    case waitingAccel = 1
    case driving = 2
    case dwelling = 3
    case recovery = 4
}

public enum WorkoutType: UInt8, Sendable, Codable {
    case justRow = 0
    case fixedDistance = 2
    case fixedTime = 4
    case timeInterval = 6
    case distanceInterval = 7
}

public enum ErgMachineType: UInt8, Sendable, Codable {
    case staticD = 0
    case staticE = 5
    case ski = 128
    case bike = 192
}

public enum RowingProtocolType: String, Sendable, Codable {
    case concept2
    case ftms
    case watchCoreMotion
}

public enum ConnectionState: Sendable {
    case disconnected
    case connecting
    case connected
    case disconnecting
}
