import Foundation

public struct ByteReader {
    private let data: Data
    public private(set) var offset: Int

    public init(_ data: Data) {
        self.data = data
        self.offset = 0
    }

    public var remaining: Int {
        data.count - offset
    }

    public mutating func readUInt8() -> UInt8 {
        let value = data[data.startIndex + offset]
        offset += 1
        return value
    }

    public mutating func readUInt16LE() -> UInt16 {
        let low = UInt16(data[data.startIndex + offset])
        let high = UInt16(data[data.startIndex + offset + 1])
        offset += 2
        return low | (high << 8)
    }

    public mutating func readUInt24LE() -> UInt32 {
        let b0 = UInt32(data[data.startIndex + offset])
        let b1 = UInt32(data[data.startIndex + offset + 1])
        let b2 = UInt32(data[data.startIndex + offset + 2])
        offset += 3
        return b0 | (b1 << 8) | (b2 << 16)
    }

    public mutating func readInt16LE() -> Int16 {
        Int16(bitPattern: readUInt16LE())
    }

    public mutating func skip(_ count: Int) {
        offset += count
    }
}
