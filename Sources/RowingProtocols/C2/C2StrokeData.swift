import Foundation

public enum C2StrokeData {
    public static let characteristicSize = 20

    public static func encode(_ snapshot: RowingSnapshot) -> Data {
        var writer = ByteWriter(capacity: characteristicSize)
        let elapsed = UInt32((snapshot.elapsedTime ?? 0) / 0.01)
        writer.writeUInt24LE(elapsed)
        let dist = UInt32((snapshot.distance ?? 0) / 0.1)
        writer.writeUInt24LE(dist)
        writer.writeUInt8(UInt8((snapshot.driveLength ?? 0) / 0.01))
        writer.writeUInt8(UInt8((snapshot.driveTime ?? 0) / 0.01))
        let recovery = UInt16((snapshot.recoveryTime ?? 0) / 0.01)
        writer.writeUInt16LE(recovery)
        let strokeDist = UInt16((snapshot.strokeDistance ?? 0) / 0.01)
        writer.writeUInt16LE(strokeDist)
        let peakForce = UInt16((snapshot.peakDriveForce ?? 0) / 0.1)
        writer.writeUInt16LE(peakForce)
        let avgForce = UInt16((snapshot.avgDriveForce ?? 0) / 0.1)
        writer.writeUInt16LE(avgForce)
        let work = UInt16((snapshot.workPerStroke ?? 0) / 0.1)
        writer.writeUInt16LE(work)
        writer.writeUInt16LE(UInt16(snapshot.strokeCount ?? 0))
        return writer.data
    }

    public static func decode(_ data: Data) -> RowingSnapshot {
        guard data.count >= characteristicSize else { return RowingSnapshot() }
        var reader = ByteReader(data)
        let elapsedRaw = reader.readUInt24LE()
        let distRaw = reader.readUInt24LE()
        let driveLength = Double(reader.readUInt8()) * 0.01
        let driveTime = Double(reader.readUInt8()) * 0.01
        let recoveryRaw = reader.readUInt16LE()
        let strokeDistRaw = reader.readUInt16LE()
        let peakForceRaw = reader.readUInt16LE()
        let avgForceRaw = reader.readUInt16LE()
        let workRaw = reader.readUInt16LE()
        let strokeCount = Int(reader.readUInt16LE())

        return RowingSnapshot(
            elapsedTime: Double(elapsedRaw) * 0.01,
            distance: Double(distRaw) * 0.1,
            strokeCount: strokeCount,
            driveLength: driveLength,
            driveTime: driveTime,
            recoveryTime: Double(recoveryRaw) * 0.01,
            strokeDistance: Double(strokeDistRaw) * 0.01,
            peakDriveForce: Double(peakForceRaw) * 0.1,
            avgDriveForce: Double(avgForceRaw) * 0.1,
            workPerStroke: Double(workRaw) * 0.1
        )
    }
}
