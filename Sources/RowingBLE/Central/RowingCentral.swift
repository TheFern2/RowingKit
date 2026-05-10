import CoreBluetooth
import RowingProtocols

public struct DiscoveredRower: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let protocolType: RowingProtocolType
    public let rssi: Int
}

@Observable
public final class RowingCentral: NSObject, @unchecked Sendable {
    public private(set) var state: CBManagerState = .unknown
    public private(set) var discoveredRowers: [DiscoveredRower] = []
    public private(set) var isScanning = false

    private var centralManager: CBCentralManager?

    public override init() {
        super.init()
    }

    public func startScanning() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        isScanning = true
        guard state == .poweredOn else { return }
        beginScan()
    }

    public func stopScanning() {
        isScanning = false
        centralManager?.stopScan()
        discoveredRowers.removeAll()
    }

    private func beginScan() {
        let services = [
            CBUUID(string: C2UUIDs.rowingService),
            CBUUID(string: FTMSUUIDs.fitnessMachineService),
        ]
        centralManager?.scanForPeripherals(withServices: services, options: nil)
    }
}

extension RowingCentral: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
        if state == .poweredOn, isScanning {
            beginScan()
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        let protocolType: RowingProtocolType
        if serviceUUIDs.contains(CBUUID(string: C2UUIDs.rowingService)) {
            protocolType = .concept2
        } else {
            protocolType = .ftms
        }

        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? peripheral.name
            ?? "Unknown Rower"

        let rower = DiscoveredRower(
            id: peripheral.identifier,
            name: name,
            protocolType: protocolType,
            rssi: RSSI.intValue
        )

        if !discoveredRowers.contains(where: { $0.id == rower.id }) {
            discoveredRowers.append(rower)
        }
    }
}
