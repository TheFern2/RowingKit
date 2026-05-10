import Foundation

public struct ByteWriter {
    public private(set) var data: Data

    public init(capacity: Int) {
        self.data = Data(capacity: capacity)
    }

    public mutating func writeUInt8(_ value: UInt8) {
        data.append(value)
    }

    public mutating func writeUInt16LE(_ value: UInt16) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
    }

    public mutating func writeUInt24LE(_ value: UInt32) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
        data.append(UInt8((value >> 16) & 0xFF))
    }

    public mutating func writeInt16LE(_ value: Int16) {
        writeUInt16LE(UInt16(bitPattern: value))
    }

    public mutating func pad(_ count: Int) {
        data.append(contentsOf: [UInt8](repeating: 0, count: count))
    }
}
