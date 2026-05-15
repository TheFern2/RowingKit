import CoreBluetooth
import RowingProtocols

@Observable
public final class RowingPeripheral: NSObject, @unchecked Sendable {
    public private(set) var state: CBManagerState = .unknown
    public private(set) var isAdvertising = false
    public private(set) var subscribedCentrals = 0

    public let protocolTypes: [RowingProtocolType]

    private var peripheralManager: CBPeripheralManager?
    private var characteristicsByProtocol: [RowingProtocolType: [CBMutableCharacteristic]] = [:]
    private var advertisingName: String = "ErgSim"
    private var pendingUpdates: [(CBMutableCharacteristic, Data)] = []

    public convenience init(protocolType: RowingProtocolType) {
        self.init(protocolTypes: [protocolType])
    }

    public init(protocolTypes: [RowingProtocolType]) {
        self.protocolTypes = protocolTypes
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
        characteristicsByProtocol.removeAll()
        pendingUpdates.removeAll()
        subscribedCentrals = 0
    }

    public func publish(snapshot: RowingSnapshot) {
        guard isAdvertising, !characteristicsByProtocol.isEmpty else { return }
        for (proto, characteristics) in characteristicsByProtocol {
            guard let handler = ProtocolRegistry.handler(for: proto) else { continue }
            for characteristic in characteristics {
                let data = handler.encode(snapshot: snapshot, characteristicUUID: characteristic.uuid.uuidString)
                let sent = peripheralManager?.updateValue(data, for: characteristic, onSubscribedCentrals: nil) ?? false
                if !sent {
                    pendingUpdates.append((characteristic, data))
                }
            }
        }
    }

    public func publish(snapshot: RowingSnapshot, for protocolType: RowingProtocolType) {
        guard isAdvertising,
              let characteristics = characteristicsByProtocol[protocolType],
              let handler = ProtocolRegistry.handler(for: protocolType) else { return }
        for characteristic in characteristics {
            let data = handler.encode(snapshot: snapshot, characteristicUUID: characteristic.uuid.uuidString)
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
        var allServiceUUIDs: [CBUUID] = []

        for proto in protocolTypes {
            guard let handler = ProtocolRegistry.handler(for: proto) else { continue }
            let definition = handler.serviceDefinition

            var allCharacteristics: [CBMutableCharacteristic] = []
            var notify: [CBMutableCharacteristic] = []

            for charDef in definition.characteristics {
                let properties: CBCharacteristicProperties = charDef.isNotify ? .notify : .write
                let permissions: CBAttributePermissions = charDef.isWritable ? .writeable : .readable
                let characteristic = CBMutableCharacteristic(
                    type: CBUUID(string: charDef.uuid), properties: properties, value: nil, permissions: permissions
                )
                allCharacteristics.append(characteristic)
                if charDef.isNotify {
                    notify.append(characteristic)
                }
            }

            characteristicsByProtocol[proto] = notify

            let service = CBMutableService(type: CBUUID(string: definition.serviceUUID), primary: true)
            service.characteristics = allCharacteristics
            peripheralManager?.add(service)

            allServiceUUIDs.append(CBUUID(string: definition.serviceUUID))
        }

        peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: allServiceUUIDs,
            CBAdvertisementDataLocalNameKey: advertisingName,
        ])
    }
}
