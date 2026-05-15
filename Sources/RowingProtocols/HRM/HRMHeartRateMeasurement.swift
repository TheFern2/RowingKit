import Foundation

public enum HRMHeartRateMeasurement {
    public static func decode(_ data: Data) -> RowingSnapshot {
        guard data.count >= 2 else { return RowingSnapshot() }
        var reader = ByteReader(data)
        let flags = reader.readUInt8()

        let hrIs16Bit = flags & 0x01 != 0
        let heartRate: Int

        if hrIs16Bit {
            guard reader.remaining >= 2 else { return RowingSnapshot() }
            heartRate = Int(reader.readUInt16LE())
        } else {
            heartRate = Int(reader.readUInt8())
        }

        return RowingSnapshot(heartRate: heartRate)
    }

    public static func encode(_ snapshot: RowingSnapshot) -> Data {
        let hr = snapshot.heartRate ?? 0
        var writer = ByteWriter(capacity: 3)

        if hr > 255 {
            writer.writeUInt8(0x01) // flags: UInt16 format
            writer.writeUInt16LE(UInt16(hr))
        } else {
            writer.writeUInt8(0x00) // flags: UInt8 format
            writer.writeUInt8(UInt8(hr))
        }

        return writer.data
    }
}
