import XCTest
@testable import RowingProtocols

final class ByteCodingTests: XCTestCase {
    func testWriterProducesLittleEndianUInt16() {
        var writer = ByteWriter(capacity: 2)
        writer.writeUInt16LE(0x0201)
        XCTAssertEqual(writer.data, Data([0x01, 0x02]))
    }

    func testWriterProducesLittleEndianUInt24() {
        var writer = ByteWriter(capacity: 3)
        writer.writeUInt24LE(0x030201)
        XCTAssertEqual(writer.data, Data([0x01, 0x02, 0x03]))
    }

    func testReaderParsesLittleEndianUInt16() {
        var reader = ByteReader(Data([0x01, 0x02]))
        let value = reader.readUInt16LE()
        XCTAssertEqual(value, 0x0201)
    }

    func testReaderParsesLittleEndianUInt24() {
        var reader = ByteReader(Data([0x01, 0x02, 0x03]))
        let value = reader.readUInt24LE()
        XCTAssertEqual(value, 0x030201)
    }

    func testInt16LESignedRoundTrip() {
        var writer = ByteWriter(capacity: 2)
        writer.writeInt16LE(-150)
        var reader = ByteReader(writer.data)
        XCTAssertEqual(reader.readInt16LE(), -150)
    }
}
