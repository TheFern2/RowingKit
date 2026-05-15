import CoreBluetooth
import RowingProtocols

public struct DiscoveredRower: Identifiable, Sendable {
    public let id: String
    public let peripheralID: UUID
    public let name: String
    public let protocolType: RowingProtocolType
    public let deviceCategory: DeviceCategory
    public let rssi: Int
}

@Observable
public final class RowingCentral: NSObject, RowingDataProvider, @unchecked Sendable {
    public let id: String
    public private(set) var displayName: String = ""
    public private(set) var protocolType: RowingProtocolType = .concept2
    public private(set) var state: CBManagerState = .unknown
    public private(set) var discoveredRowers: [DiscoveredRower] = []
    public private(set) var isScanning = false
    public private(set) var connectionState: ConnectionState = .disconnected
    public private(set) var hrmConnectionState: ConnectionState = .disconnected
    public private(set) var connectedRowerName: String?
    public private(set) var connectedHRMName: String?
    public private(set) var latestSnapshot: RowingSnapshot?
    public private(set) var latestHRMHeartRate: Int?

    public var snapshotStream: AsyncStream<RowingSnapshot> {
        AsyncStream { continuation in
            snapshotContinuation = continuation
        }
    }

    private let configuration: BLEConfiguration
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var connectedHRMPeripheral: CBPeripheral?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var connectedProtocolType: RowingProtocolType?
    private var connectedHRMProtocolType: RowingProtocolType?
    private var pendingSnapshot = RowingSnapshot()
    private var snapshotContinuation: AsyncStream<RowingSnapshot>.Continuation?
    private var connectionTimeoutTask: Task<Void, Never>?
    private var hrmConnectionTimeoutTask: Task<Void, Never>?

    public init(configuration: BLEConfiguration = .default) {
        self.id = UUID().uuidString
        self.configuration = configuration
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

    public func connectErg(to rower: DiscoveredRower) {
        guard let peripheral = discoveredPeripherals[rower.peripheralID] else { return }
        connectedPeripheral = peripheral
        connectionState = .connecting
        connectedProtocolType = rower.protocolType
        protocolType = rower.protocolType
        connectedRowerName = rower.name
        displayName = rower.name
        centralManager?.connect(peripheral, options: nil)
        startConnectionTimeout()
    }

    public func connectHRM(to rower: DiscoveredRower) {
        guard let peripheral = discoveredPeripherals[rower.peripheralID] else { return }
        connectedHRMPeripheral = peripheral
        hrmConnectionState = .connecting
        connectedHRMProtocolType = rower.protocolType
        connectedHRMName = rower.name
        centralManager?.connect(peripheral, options: nil)
        startHRMConnectionTimeout()
    }

    public func disconnectErg() {
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = nil
        guard let peripheral = connectedPeripheral else { return }
        connectionState = .disconnecting
        centralManager?.cancelPeripheralConnection(peripheral)
    }

    public func disconnectHRM() {
        hrmConnectionTimeoutTask?.cancel()
        hrmConnectionTimeoutTask = nil
        guard let peripheral = connectedHRMPeripheral else { return }
        hrmConnectionState = .disconnecting
        centralManager?.cancelPeripheralConnection(peripheral)
    }

    private func beginScan() {
        let services = ProtocolRegistry.scanServiceUUIDs.map { CBUUID(string: $0) }
        centralManager?.scanForPeripherals(
            withServices: services,
            options: configuration.scanDuplicates
                ? [CBCentralManagerScanOptionAllowDuplicatesKey: true]
                : nil
        )
    }

    private func resetErgConnection() {
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = nil
        connectedPeripheral = nil
        connectedProtocolType = nil
        connectedRowerName = nil
        latestSnapshot = nil
        pendingSnapshot = RowingSnapshot()
        connectionState = .disconnected
        snapshotContinuation?.finish()
        snapshotContinuation = nil
    }

    private func resetHRMConnection() {
        hrmConnectionTimeoutTask?.cancel()
        hrmConnectionTimeoutTask = nil
        connectedHRMPeripheral = nil
        connectedHRMProtocolType = nil
        connectedHRMName = nil
        latestHRMHeartRate = nil
        hrmConnectionState = .disconnected
    }

    private func startConnectionTimeout() {
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = Task { [weak self, timeout = configuration.connectionTimeout] in
            try? await Task.sleep(for: .seconds(timeout))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.connectionState == .connecting else { return }
                self.disconnectErg()
            }
        }
    }

    private func startHRMConnectionTimeout() {
        hrmConnectionTimeoutTask?.cancel()
        hrmConnectionTimeoutTask = Task { [weak self, timeout = configuration.connectionTimeout] in
            try? await Task.sleep(for: .seconds(timeout))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.hrmConnectionState == .connecting else { return }
                self.disconnectHRM()
            }
        }
    }

    private func discoverServicesForPeripheral(_ peripheral: CBPeripheral, protocolType: RowingProtocolType) {
        guard let handler = ProtocolRegistry.handler(for: protocolType) else { return }
        peripheral.discoverServices([CBUUID(string: handler.serviceUUID)])
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
        if let v = partial.averagePower { pendingSnapshot.averagePower = v }
        if let v = partial.heartRate { pendingSnapshot.heartRate = v }
        if let v = partial.calories { pendingSnapshot.calories = v }
        if let v = partial.caloriesPerHour { pendingSnapshot.caloriesPerHour = v }
        if let v = partial.caloriesPerMinute { pendingSnapshot.caloriesPerMinute = v }
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
        if let v = partial.resistanceLevel { pendingSnapshot.resistanceLevel = v }
        if let v = partial.metabolicEquivalent { pendingSnapshot.metabolicEquivalent = v }
        if let v = partial.remainingTime { pendingSnapshot.remainingTime = v }
        if let v = partial.projectedWorkTime { pendingSnapshot.projectedWorkTime = v }
        if let v = partial.projectedWorkDistance { pendingSnapshot.projectedWorkDistance = v }
        latestSnapshot = pendingSnapshot
        snapshotContinuation?.yield(pendingSnapshot)
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
        let matchedHandlers = serviceUUIDs.compactMap { uuid in
            ProtocolRegistry.handler(forServiceUUID: uuid.uuidString)
        }
        guard !matchedHandlers.isEmpty else { return }

        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? peripheral.name
            ?? "Unknown Rower"

        discoveredPeripherals[peripheral.identifier] = peripheral

        for handler in matchedHandlers {
            let compositeID = "\(peripheral.identifier.uuidString)-\(handler.protocolType.rawValue)"
            if discoveredRowers.contains(where: { $0.id == compositeID }) { continue }
            let rower = DiscoveredRower(
                id: compositeID,
                peripheralID: peripheral.identifier,
                name: name,
                protocolType: handler.protocolType,
                deviceCategory: DeviceCategory(protocolType: handler.protocolType),
                rssi: RSSI.intValue
            )
            discoveredRowers.append(rower)
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral.identifier == connectedPeripheral?.identifier {
            connectionTimeoutTask?.cancel()
            connectionTimeoutTask = nil
            if let name = peripheral.name, connectedRowerName == nil || connectedRowerName == "Unknown Rower" {
                connectedRowerName = name
                displayName = name
            }
            connectionState = .connected
            peripheral.delegate = self
            if let proto = connectedProtocolType {
                discoverServicesForPeripheral(peripheral, protocolType: proto)
            }
        } else if peripheral.identifier == connectedHRMPeripheral?.identifier {
            hrmConnectionTimeoutTask?.cancel()
            hrmConnectionTimeoutTask = nil
            if let name = peripheral.name, connectedHRMName == nil || connectedHRMName == "Unknown Rower" {
                connectedHRMName = name
            }
            hrmConnectionState = .connected
            peripheral.delegate = self
            if let proto = connectedHRMProtocolType {
                discoverServicesForPeripheral(peripheral, protocolType: proto)
            }
        }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        if peripheral.identifier == connectedPeripheral?.identifier {
            resetErgConnection()
        } else if peripheral.identifier == connectedHRMPeripheral?.identifier {
            resetHRMConnection()
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        if peripheral.identifier == connectedPeripheral?.identifier {
            resetErgConnection()
        } else if peripheral.identifier == connectedHRMPeripheral?.identifier {
            resetHRMConnection()
        }
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

        if peripheral.identifier == connectedHRMPeripheral?.identifier {
            guard let proto = connectedHRMProtocolType,
                  let handler = ProtocolRegistry.handler(for: proto),
                  let partial = handler.decode(characteristicUUID: characteristic.uuid.uuidString, data: data)
            else { return }
            latestHRMHeartRate = partial.heartRate
        } else {
            guard let proto = connectedProtocolType,
                  let handler = ProtocolRegistry.handler(for: proto),
                  let partial = handler.decode(characteristicUUID: characteristic.uuid.uuidString, data: data)
            else { return }
            mergeSnapshot(partial)
        }
    }
}
