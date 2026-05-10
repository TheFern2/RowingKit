import Foundation

public enum FTMSRowerData {
    public static func encode(_ snapshot: RowingSnapshot) -> Data {
        var flags: UInt16 = 0
        var writer = ByteWriter(capacity: 30)
        writer.writeUInt16LE(0) // placeholder for flags

        // Bit 0 inverted: when bit 0 is 0, stroke rate + count ARE present
        if snapshot.strokeRate != nil || snapshot.strokeCount != nil {
            // leave bit 0 as 0 (present)
            let rate = UInt8((snapshot.strokeRate ?? 0) * 2)
            writer.writeUInt8(rate)
            writer.writeUInt16LE(UInt16(snapshot.strokeCount ?? 0))
        } else {
            flags |= 0x0001 // set bit 0 = not present
        }

        if let distance = snapshot.distance {
            flags |= 0x0004 // bit 2
            writer.writeUInt24LE(UInt32(distance))
        }

        if let pace = snapshot.pace {
            flags |= 0x0008 // bit 3
            writer.writeUInt16LE(UInt16(pace))
        }

        if let power = snapshot.power {
            flags |= 0x0020 // bit 5
            writer.writeInt16LE(Int16(power))
        }

        if let calories = snapshot.calories {
            flags |= 0x0100 // bit 8
            writer.writeUInt16LE(UInt16(calories))
            writer.writeUInt16LE(UInt16(snapshot.caloriesPerHour ?? 0))
            writer.writeUInt8(UInt8(snapshot.caloriesPerMinute ?? 0))
        }

        if let heartRate = snapshot.heartRate {
            flags |= 0x0200 // bit 9
            writer.writeUInt8(UInt8(heartRate))
        }

        if let elapsed = snapshot.elapsedTime {
            flags |= 0x0800 // bit 11
            writer.writeUInt16LE(UInt16(elapsed))
        }

        // Write flags back at position 0
        var result = writer.data
        result[0] = UInt8(flags & 0xFF)
        result[1] = UInt8((flags >> 8) & 0xFF)
        return result
    }

    public static func decode(_ data: Data) -> RowingSnapshot {
        guard data.count >= 2 else { return RowingSnapshot() }
        var reader = ByteReader(data)
        let flags = reader.readUInt16LE()
        var snapshot = RowingSnapshot()

        // Bit 0 inverted: 0 means stroke rate + count present
        if flags & 0x0001 == 0 {
            let rateRaw = reader.readUInt8()
            snapshot.strokeRate = Int(rateRaw) / 2
            snapshot.strokeCount = Int(reader.readUInt16LE())
        }

        // Bit 1: average stroke rate
        if flags & 0x0002 != 0 {
            reader.skip(1)
        }

        // Bit 2: total distance
        if flags & 0x0004 != 0 {
            snapshot.distance = Double(reader.readUInt24LE())
        }

        // Bit 3: instantaneous pace
        if flags & 0x0008 != 0 {
            snapshot.pace = Double(reader.readUInt16LE())
        }

        // Bit 4: average pace
        if flags & 0x0010 != 0 {
            snapshot.averagePace = Double(reader.readUInt16LE())
        }

        // Bit 5: instantaneous power
        if flags & 0x0020 != 0 {
            snapshot.power = Int(reader.readInt16LE())
        }

        // Bit 6: average power
        if flags & 0x0040 != 0 {
            snapshot.averagePower = Int(reader.readInt16LE())
        }

        // Bit 7: resistance level
        if flags & 0x0080 != 0 {
            snapshot.resistanceLevel = Int(reader.readInt16LE())
        }

        // Bit 8: expended energy
        if flags & 0x0100 != 0 {
            snapshot.calories = Int(reader.readUInt16LE())
            snapshot.caloriesPerHour = Int(reader.readUInt16LE())
            snapshot.caloriesPerMinute = Int(reader.readUInt8())
        }

        // Bit 9: heart rate
        if flags & 0x0200 != 0 {
            snapshot.heartRate = Int(reader.readUInt8())
        }

        // Bit 10: metabolic equivalent
        if flags & 0x0400 != 0 {
            snapshot.metabolicEquivalent = Double(reader.readUInt8()) / 10.0
        }

        // Bit 11: elapsed time
        if flags & 0x0800 != 0 {
            snapshot.elapsedTime = Double(reader.readUInt16LE())
        }

        // Bit 12: remaining time
        if flags & 0x1000 != 0 {
            snapshot.remainingTime = Double(reader.readUInt16LE())
        }

        return snapshot
    }
}
