import Foundation

public enum C2AdditionalStrokeData {
    public static let characteristicSize = 15

    public static func encode(_ snapshot: RowingSnapshot) -> Data {
        var writer = ByteWriter(capacity: characteristicSize)
        let elapsed = UInt32((snapshot.elapsedTime ?? 0) / 0.01)
        writer.writeUInt24LE(elapsed)
        writer.writeUInt16LE(UInt16(snapshot.power ?? 0))
        writer.writeUInt16LE(UInt16(snapshot.caloriesPerHour ?? 0))
        writer.writeUInt16LE(UInt16(snapshot.strokeCount ?? 0))
        let projTime = UInt32(snapshot.projectedWorkTime ?? 0)
        writer.writeUInt24LE(projTime)
        let projDist = UInt32(snapshot.projectedWorkDistance ?? 0)
        writer.writeUInt24LE(projDist)
        return writer.data
    }

    public static func decode(_ data: Data) -> RowingSnapshot {
        guard data.count >= characteristicSize else { return RowingSnapshot() }
        var reader = ByteReader(data)
        let elapsedRaw = reader.readUInt24LE()
        let power = Int(reader.readUInt16LE())
        let calsPerHour = Int(reader.readUInt16LE())
        let strokeCount = Int(reader.readUInt16LE())
        let projTimeRaw = reader.readUInt24LE()
        let projDistRaw = reader.readUInt24LE()

        return RowingSnapshot(
            elapsedTime: Double(elapsedRaw) * 0.01,
            strokeCount: strokeCount,
            power: power,
            caloriesPerHour: calsPerHour,
            projectedWorkTime: Double(projTimeRaw),
            projectedWorkDistance: Double(projDistRaw)
        )
    }
}
