import CoreBluetooth
import RowingProtocols

@Observable
public final class RowingPeripheral: NSObject, @unchecked Sendable {
    public private(set) var state: CBManagerState = .unknown
    public private(set) var isAdvertising = false
    public private(set) var subscribedCentrals = 0

    public let protocolType: RowingProtocolType

    private var peripheralManager: CBPeripheralManager?
    private var notifyCharacteristics: [CBMutableCharacteristic] = []
    private var advertisingName: String = "ErgSim"
    private var pendingUpdates: [(CBMutableCharacteristic, Data)] = []

    public init(protocolType: RowingProtocolType) {
        self.protocolType = protocolType
        super.init()
    }

    public func startAdvertising(name: String) {
        advertisingName = name
        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        }
        isAdvertising = true
        if state == .poweredOn {
            setupServices()
        }
    }

    public func stopAdvertising() {
        isAdvertising = false
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()
        notifyCharacteristics.removeAll()
        subscribedCentrals = 0
    }

    public func publish(snapshot: RowingSnapshot) {
        guard isAdvertising, !notifyCharacteristics.isEmpty else { return }
        for characteristic in notifyCharacteristics {
            let data = encodeForCharacteristic(characteristic, snapshot: snapshot)
            let sent = peripheralManager?.updateValue(data, for: characteristic, onSubscribedCentrals: nil) ?? false
            if !sent {
                pendingUpdates.append((characteristic, data))
            }
        }
    }

    private func drainPendingUpdates() {
        while !pendingUpdates.isEmpty {
            let (characteristic, data) = pendingUpdates[0]
            let sent = peripheralManager?.updateValue(data, for: characteristic, onSubscribedCentrals: nil) ?? false
            if sent {
                pendingUpdates.removeFirst()
            } else {
                break
            }
        }
    }

    private func encodeForCharacteristic(_ characteristic: CBMutableCharacteristic, snapshot: RowingSnapshot) -> Data {
        switch protocolType {
        case .concept2:
            return encodeC2(characteristic: characteristic, snapshot: snapshot)
        case .ftms:
            return FTMSRowerData.encode(snapshot)
        case .watchCoreMotion:
            return Data()
        }
    }

    private func encodeC2(characteristic: CBMutableCharacteristic, snapshot: RowingSnapshot) -> Data {
        let uuid = characteristic.uuid
        if uuid == CBUUID(string: C2UUIDs.generalStatus) {
            return C2GeneralStatus.encode(snapshot)
        } else if uuid == CBUUID(string: C2UUIDs.additionalStatus1) {
            return C2AdditionalStatus1.encode(snapshot)
        } else if uuid == CBUUID(string: C2UUIDs.strokeData) {
            return C2StrokeData.encode(snapshot)
        } else if uuid == CBUUID(string: C2UUIDs.additionalStrokeData) {
            return C2AdditionalStrokeData.encode(snapshot)
        }
        return Data()
    }
}

extension RowingPeripheral: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        state = peripheral.state
        if state == .poweredOn, isAdvertising {
            setupServices()
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        subscribedCentrals += 1
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        subscribedCentrals = max(0, subscribedCentrals - 1)
    }

    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        drainPendingUpdates()
    }

    private func setupServices() {
        switch protocolType {
        case .concept2:
            setupC2Services()
        case .ftms:
            setupFTMSServices()
        case .watchCoreMotion:
            break
        }
    }

    private func setupC2Services() {
        let generalStatus = CBMutableCharacteristic(
            type: CBUUID(string: C2UUIDs.generalStatus), properties: .notify, value: nil, permissions: .readable
        )
        let additionalStatus1 = CBMutableCharacteristic(
            type: CBUUID(string: C2UUIDs.additionalStatus1), properties: .notify, value: nil, permissions: .readable
        )
        let strokeData = CBMutableCharacteristic(
            type: CBUUID(string: C2UUIDs.strokeData), properties: .notify, value: nil, permissions: .readable
        )
        let additionalStrokeData = CBMutableCharacteristic(
            type: CBUUID(string: C2UUIDs.additionalStrokeData), properties: .notify, value: nil, permissions: .readable
        )
        let sampleRate = CBMutableCharacteristic(
            type: CBUUID(string: C2UUIDs.sampleRate), properties: .write, value: nil, permissions: .writeable
        )

        notifyCharacteristics = [generalStatus, additionalStatus1, strokeData, additionalStrokeData]

        let service = CBMutableService(type: CBUUID(string: C2UUIDs.rowingService), primary: true)
        service.characteristics = [generalStatus, additionalStatus1, strokeData, additionalStrokeData, sampleRate]
        peripheralManager?.add(service)

        peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: C2UUIDs.rowingService)],
            CBAdvertisementDataLocalNameKey: advertisingName,
        ])
    }

    private func setupFTMSServices() {
        let rowerData = CBMutableCharacteristic(
            type: CBUUID(string: FTMSUUIDs.rowerData), properties: .notify, value: nil, permissions: .readable
        )

        notifyCharacteristics = [rowerData]

        let service = CBMutableService(type: CBUUID(string: FTMSUUIDs.fitnessMachineService), primary: true)
        service.characteristics = [rowerData]
        peripheralManager?.add(service)

        peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: FTMSUUIDs.fitnessMachineService)],
            CBAdvertisementDataLocalNameKey: advertisingName,
        ])
    }
}
