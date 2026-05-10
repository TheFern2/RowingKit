import Foundation

public enum C2AdditionalStatus1 {
    public static let characteristicSize = 17

    public static func encode(_ snapshot: RowingSnapshot) -> Data {
        var writer = ByteWriter(capacity: characteristicSize)
        let elapsed = UInt32((snapshot.elapsedTime ?? 0) / 0.01)
        writer.writeUInt24LE(elapsed)
        let speed = UInt16((snapshot.speed ?? 0) / 0.001)
        writer.writeUInt16LE(speed)
        writer.writeUInt8(UInt8(snapshot.strokeRate ?? 0))
        writer.writeUInt8(UInt8(min(snapshot.heartRate ?? 255, 255)))
        let pace = UInt16((snapshot.pace ?? 0) / 0.01)
        writer.writeUInt16LE(pace)
        let avgPace = UInt16((snapshot.averagePace ?? 0) / 0.01)
        writer.writeUInt16LE(avgPace)
        writer.writeUInt16LE(0) // rest distance
        writer.writeUInt24LE(0) // rest time
        writer.writeUInt8(0) // erg machine type
        return writer.data
    }

    public static func decode(_ data: Data) -> RowingSnapshot {
        guard data.count >= characteristicSize else { return RowingSnapshot() }
        var reader = ByteReader(data)
        let elapsedRaw = reader.readUInt24LE()
        let speedRaw = reader.readUInt16LE()
        let strokeRate = Int(reader.readUInt8())
        let heartRate = Int(reader.readUInt8())
        let paceRaw = reader.readUInt16LE()
        let avgPaceRaw = reader.readUInt16LE()
        reader.skip(2) // rest distance
        reader.skip(3) // rest time
        let ergType = ErgMachineType(rawValue: reader.readUInt8())

        return RowingSnapshot(
            elapsedTime: Double(elapsedRaw) * 0.01,
            strokeRate: strokeRate,
            pace: Double(paceRaw) * 0.01,
            averagePace: Double(avgPaceRaw) * 0.01,
            speed: Double(speedRaw) * 0.001,
            heartRate: heartRate == 255 ? nil : heartRate,
            ergMachineType: ergType
        )
    }
}
