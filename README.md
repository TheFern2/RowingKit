# RowingKit

A Swift package for rowing machine communication. Two modules: **RowingProtocols** (data models, protocol encoding/decoding) and **RowingBLE** (CoreBluetooth central and peripheral roles).

## Platforms

- iOS 17+
- macOS 14+
- watchOS 10+
- Swift 6

## Installation

Add RowingKit as a Swift Package dependency:

```swift
dependencies: [
    .package(url: "https://github.com/<owner>/RowingKit.git", from: "0.1.0")
]
```

Then add the products you need to your target:

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "RowingProtocols", package: "RowingKit"),
    .product(name: "RowingBLE", package: "RowingKit"),
])
```

`RowingProtocols` can be used standalone for data modeling without CoreBluetooth.

## Modules

### RowingProtocols

Data models and protocol encoding/decoding with no CoreBluetooth dependency.

**Core types:**
- `RowingSnapshot` — struct with 30+ optional rowing metric fields (elapsed time, distance, stroke rate, power, pace, heart rate, calories, drive/recovery times, force data, workout/rowing/stroke state, and more)
- `RowingDataProvider` — protocol for any source of rowing data, exposes `latestSnapshot` and `snapshotStream: AsyncStream<RowingSnapshot>`
- `ConnectionState` — disconnected, connecting, connected, disconnecting
- Workout/rowing/stroke state enums, workout types, erg machine types

**Concept2 PM5 protocol:**
- `C2GeneralStatus` — encode/decode (19 bytes): elapsed time, distance, workout/rowing/stroke state, drag factor
- `C2AdditionalStatus1` — encode/decode (17 bytes): speed, stroke rate, heart rate, pace
- `C2StrokeData` — encode/decode (20 bytes): drive/recovery times, forces, work per stroke, stroke count
- `C2AdditionalStrokeData` — encode/decode (15 bytes): power, calories, projected time/distance
- `C2UUIDs` — service and characteristic UUIDs

**FTMS (Fitness Machine Service):**
- `FTMSRowerData` — encode/decode with flag-based variable fields: stroke rate, distance, pace, power, calories, heart rate, elapsed time, and more
- `FTMSUUIDs` — service and characteristic UUIDs

**Byte coding:**
- `ByteReader` / `ByteWriter` — little-endian binary encoding/decoding (UInt8, UInt16, UInt24, Int16)

### RowingBLE

CoreBluetooth central and peripheral implementations.

**`RowingCentral`** — scan, connect, and receive data from rowing machines.
- Conforms to `RowingDataProvider`
- Scans for both C2 and FTMS services
- Connects, discovers services/characteristics, subscribes to notifications
- Decodes incoming data into `RowingSnapshot` with cross-characteristic merging (C2 splits data across 4 characteristics)
- Configurable via `BLEConfiguration` (scan duplicates, connection timeout)
- Exposes `latestSnapshot` (@Observable) and `snapshotStream` (AsyncStream)

**`RowingPeripheral`** — advertise as a rowing machine and publish data.
- Supports C2 and FTMS protocols
- Advertises with configurable name and service UUIDs
- Publishes `RowingSnapshot` encoded to the appropriate protocol characteristics
- Handles transmit queue overflow with pending update queue and `peripheralManagerIsReady(toUpdateSubscribers:)` drain

**`BLEConfiguration`** — configurable options for the central role: restore identifier, scan duplicates, connection timeout, C2 sample rate.

## Usage

### Central (receive data from an erg)

```swift
import RowingBLE

let central = RowingCentral()

// Scan
central.startScanning()

// Connect to a discovered rower
if let rower = central.discoveredRowers.first {
    central.connect(to: rower)
}

// Observe snapshots
for await snapshot in central.snapshotStream {
    print(snapshot.power, snapshot.strokeRate, snapshot.distance)
}
```

### Peripheral (simulate an erg)

```swift
import RowingBLE
import RowingProtocols

let peripheral = RowingPeripheral(protocolType: .concept2)
peripheral.startAdvertising(name: "My Erg")

let snapshot = RowingSnapshot(
    elapsedTime: 60.0,
    distance: 250.0,
    strokeRate: 28,
    power: 200
)
peripheral.publish(snapshot: snapshot)
```

## Package Structure

```
Sources/
  RowingProtocols/
    Core/           RowingSnapshot, RowingDataProvider, enums
    C2/             Concept2 PM5 characteristic encode/decode
    FTMS/           Fitness Machine Service encode/decode
    UUIDs/          BLE service and characteristic UUIDs
    ByteCoding/     Little-endian binary reader/writer
  RowingBLE/
    Central/        RowingCentral (scan, connect, receive)
    Peripheral/     RowingPeripheral (advertise, publish)
    Shared/         BLEConfiguration
```

## Protocol Coverage

| Feature | C2 PM5 | FTMS |
|---------|--------|------|
| Elapsed time | yes | yes |
| Distance | yes | yes |
| Stroke rate | yes | yes |
| Power | yes | yes |
| Pace | yes | yes |
| Heart rate | yes | yes |
| Calories | yes | yes |
| Drive/recovery times | yes | no |
| Drive forces | yes | no |
| Work per stroke | yes | no |
| Workout/rowing/stroke state | yes | no |
| Drag factor | yes | no |
| Resistance level | no | yes |
| Metabolic equivalent | no | yes |
| Force curve | not yet | n/a |
| Machine control | n/a | not yet |
