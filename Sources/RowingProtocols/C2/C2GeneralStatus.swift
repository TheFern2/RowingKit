import Foundation

public enum C2GeneralStatus {
    public static let characteristicSize = 19

    public static func encode(_ snapshot: RowingSnapshot) -> Data {
        var writer = ByteWriter(capacity: characteristicSize)
        let elapsed = UInt32((snapshot.elapsedTime ?? 0) / 0.01)
        writer.writeUInt24LE(elapsed)
        let dist = UInt32((snapshot.distance ?? 0) / 0.1)
        writer.writeUInt24LE(dist)
        writer.writeUInt8(snapshot.workoutType?.rawValue ?? 0)
        writer.writeUInt8(0) // interval type
        writer.writeUInt8(snapshot.workoutState?.rawValue ?? 0)
        writer.writeUInt8(snapshot.rowingState?.rawValue ?? 0)
        writer.writeUInt8(snapshot.strokeState?.rawValue ?? 0)
        let totalWork = UInt32(snapshot.distance ?? 0)
        writer.writeUInt24LE(totalWork)
        writer.writeUInt24LE(0) // workout duration
        writer.writeUInt8(0x00) // duration type (time)
        writer.writeUInt8(UInt8(snapshot.dragFactor ?? 0))
        return writer.data
    }

    public static func decode(_ data: Data) -> RowingSnapshot {
        guard data.count >= characteristicSize else { return RowingSnapshot() }
        var reader = ByteReader(data)
        let elapsedRaw = reader.readUInt24LE()
        let distRaw = reader.readUInt24LE()
        let workoutType = WorkoutType(rawValue: reader.readUInt8())
        reader.skip(1) // interval type
        let workoutState = WorkoutState(rawValue: reader.readUInt8())
        let rowingState = RowingState(rawValue: reader.readUInt8())
        let strokeState = StrokeState(rawValue: reader.readUInt8())
        reader.skip(3) // total work distance
        reader.skip(3) // workout duration
        reader.skip(1) // duration type
        let dragFactor = Int(reader.readUInt8())

        return RowingSnapshot(
            elapsedTime: Double(elapsedRaw) * 0.01,
            distance: Double(distRaw) * 0.1,
            dragFactor: dragFactor,
            workoutState: workoutState,
            rowingState: rowingState,
            strokeState: strokeState,
            workoutType: workoutType
        )
    }
}
