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
    public private(set) var connectionState: ConnectionState = .disconnected
    public private(set) var connectedRowerName: String?
    public private(set) var latestSnapshot: RowingSnapshot?

    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var connectedProtocolType: RowingProtocolType?
    private var pendingSnapshot = RowingSnapshot()

    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    public func startScanning() {
        isScanning = true
        guard state == .poweredOn else { return }
        beginScan()
    }

    public func stopScanning() {
        isScanning = false
        centralManager?.stopScan()
        discoveredRowers.removeAll()
        discoveredPeripherals.removeAll()
    }

    public func connect(to rower: DiscoveredRower) {
        guard let peripheral = discoveredPeripherals[rower.id] else { return }
        stopScanning()
        connectionState = .connecting
        connectedProtocolType = rower.protocolType
        connectedRowerName = rower.name
        centralManager?.connect(peripheral, options: nil)
    }

    public func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        connectionState = .disconnecting
        centralManager?.cancelPeripheralConnection(peripheral)
    }

    private func beginScan() {
        let services = [
            CBUUID(string: C2UUIDs.rowingService),
            CBUUID(string: FTMSUUIDs.fitnessMachineService),
        ]
        centralManager?.scanForPeripherals(withServices: services, options: nil)
    }

    private func resetConnection() {
        connectedPeripheral = nil
        connectedProtocolType = nil
        connectedRowerName = nil
        latestSnapshot = nil
        pendingSnapshot = RowingSnapshot()
        connectionState = .disconnected
    }

    private func mergeSnapshot(_ partial: RowingSnapshot) {
        if let v = partial.elapsedTime { pendingSnapshot.elapsedTime = v }
        if let v = partial.distance { pendingSnapshot.distance = v }
        if let v = partial.strokeRate { pendingSnapshot.strokeRate = v }
        if let v = partial.strokeCount { pendingSnapshot.strokeCount = v }
        if let v = partial.pace { pendingSnapshot.pace = v }
        if let v = partial.averagePace { pendingSnapshot.averagePace = v }
        if let v = partial.speed { pendingSnapshot.speed = v }
        if let v = partial.power { pendingSnapshot.power = v }
        if let v = partial.heartRate { pendingSnapshot.heartRate = v }
        if let v = partial.calories { pendingSnapshot.calories = v }
        if let v = partial.caloriesPerHour { pendingSnapshot.caloriesPerHour = v }
        if let v = partial.dragFactor { pendingSnapshot.dragFactor = v }
        if let v = partial.driveLength { pendingSnapshot.driveLength = v }
        if let v = partial.driveTime { pendingSnapshot.driveTime = v }
        if let v = partial.recoveryTime { pendingSnapshot.recoveryTime = v }
        if let v = partial.strokeDistance { pendingSnapshot.strokeDistance = v }
        if let v = partial.peakDriveForce { pendingSnapshot.peakDriveForce = v }
        if let v = partial.avgDriveForce { pendingSnapshot.avgDriveForce = v }
        if let v = partial.workPerStroke { pendingSnapshot.workPerStroke = v }
        if let v = partial.workoutState { pendingSnapshot.workoutState = v }
        if let v = partial.rowingState { pendingSnapshot.rowingState = v }
        if let v = partial.strokeState { pendingSnapshot.strokeState = v }
        if let v = partial.workoutType { pendingSnapshot.workoutType = v }
        if let v = partial.ergMachineType { pendingSnapshot.ergMachineType = v }
        if let v = partial.projectedWorkTime { pendingSnapshot.projectedWorkTime = v }
        if let v = partial.projectedWorkDistance { pendingSnapshot.projectedWorkDistance = v }
        latestSnapshot = pendingSnapshot
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

        discoveredPeripherals[peripheral.identifier] = peripheral

        if !discoveredRowers.contains(where: { $0.id == rower.id }) {
            discoveredRowers.append(rower)
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        connectionState = .connected
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: C2UUIDs.rowingService)])
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        resetConnection()
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        resetConnection()
    }
}

extension RowingCentral: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics where characteristic.properties.contains(.notify) {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard let data = characteristic.value else { return }
        let uuid = characteristic.uuid.uuidString.uppercased()
        let c2General = C2UUIDs.generalStatus.uppercased()
        let c2Additional1 = C2UUIDs.additionalStatus1.uppercased()
        let c2Stroke = C2UUIDs.strokeData.uppercased()
        let c2AdditionalStroke = C2UUIDs.additionalStrokeData.uppercased()

        let partial: RowingSnapshot
        if uuid == c2General {
            partial = C2GeneralStatus.decode(data)
        } else if uuid == c2Additional1 {
            partial = C2AdditionalStatus1.decode(data)
        } else if uuid == c2Stroke {
            partial = C2StrokeData.decode(data)
        } else if uuid == c2AdditionalStroke {
            partial = C2AdditionalStrokeData.decode(data)
        } else {
            return
        }
        mergeSnapshot(partial)
    }
}
