import Flutter
import CoreBluetooth
import os.log

/// Platform channel handler for BLE peripheral-mode advertising.
///
/// Uses CBPeripheralManager to advertise the Field Link GATT service so
/// that central-mode scanners (the joiners) can discover the session host.
///
/// The GATT service contains four characteristics matching the central-
/// mode subscription UUIDs in BleConstants:
///   - position   (read + notify + write)
///   - marker     (read + notify + write)
///   - control    (read + notify + write)
///   - annotation (read + notify + write)
///
/// Incoming writes from connected centrals are forwarded to Dart via an
/// EventChannel so the sync engine can process them identically to data
/// received in central mode.
///
/// Method channel: com.redgrid.link/ble_advertiser
/// Event channel:  com.redgrid.link/ble_advertiser/events
class BleAdvertiserChannel: NSObject {

    // MARK: - Constants

    private static let methodChannelName = "com.redgrid.link/ble_advertiser"
    private static let eventChannelName = "com.redgrid.link/ble_advertiser/events"

    /// Must match BleConstants.fieldLinkServiceUuid on the Dart side.
    private static let serviceUUID = CBUUID(string: "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d")

    /// Characteristic UUIDs — must match BleConstants on the Dart side.
    private static let positionCharUUID  = CBUUID(string: "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5e")
    private static let markerCharUUID    = CBUUID(string: "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5f")
    private static let controlCharUUID   = CBUUID(string: "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c60")
    private static let annotationCharUUID = CBUUID(string: "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c61")

    private let log = OSLog(subsystem: "com.redgrid.link", category: "BleAdvertiser")

    // MARK: - Flutter channels

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    // MARK: - Core Bluetooth

    private var peripheralManager: CBPeripheralManager?
    private var gattService: CBMutableService?
    private var positionChar: CBMutableCharacteristic?
    private var markerChar: CBMutableCharacteristic?
    private var controlChar: CBMutableCharacteristic?
    private var annotationChar: CBMutableCharacteristic?

    /// Whether we should start advertising as soon as the peripheral manager
    /// powers on. Set to true when `startAdvertising` is called before the
    /// manager is ready.
    private var pendingAdvertise = false
    private var pendingSessionId: String?

    /// Centrals that have subscribed to notifications.
    private var subscribedCentrals: [CBCentral] = []

    // MARK: - Registration

    func register(with messenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: BleAdvertiserChannel.methodChannelName,
            binaryMessenger: messenger
        )
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }

        eventChannel = FlutterEventChannel(
            name: BleAdvertiserChannel.eventChannelName,
            binaryMessenger: messenger
        )
        eventChannel?.setStreamHandler(self)

        os_log("BleAdvertiserChannel registered", log: log, type: .info)
    }

    func unregister() {
        stopAdvertising()
        methodChannel?.setMethodCallHandler(nil)
        methodChannel = nil
        eventChannel?.setStreamHandler(nil)
        eventChannel = nil
        eventSink = nil
    }

    // MARK: - Method dispatch

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startAdvertising":
            guard let args = call.arguments as? [String: Any],
                  let sessionId = args["sessionId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "sessionId required", details: nil))
                return
            }
            startAdvertising(sessionId: sessionId, result: result)
        case "stopAdvertising":
            stopAdvertising()
            result(nil)
        case "updateValue":
            guard let args = call.arguments as? [String: Any],
                  let charUuid = args["characteristicUuid"] as? String,
                  let data = args["data"] as? FlutterStandardTypedData else {
                result(FlutterError(code: "INVALID_ARGS", message: "characteristicUuid and data required", details: nil))
                return
            }
            updateCharacteristicValue(charUuid: charUuid, data: data.data, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Advertising

    private func startAdvertising(sessionId: String, result: @escaping FlutterResult) {
        pendingSessionId = sessionId

        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        }

        guard peripheralManager?.state == .poweredOn else {
            // Manager not ready yet; will start advertising in
            // peripheralManagerDidUpdateState once powered on.
            pendingAdvertise = true
            os_log("Peripheral manager not ready; advertising deferred", log: log, type: .info)
            result(nil)
            return
        }

        buildAndAdvertise()
        result(nil)
    }

    /// Whether we should start advertising once the GATT service has been
    /// confirmed registered via `peripheralManager(_:didAdd:error:)`.
    private var pendingStartAdvertising = false

    private func buildAndAdvertise() {
        guard let pm = peripheralManager else { return }

        // Build GATT service if not already built
        if gattService == nil {
            let properties: CBCharacteristicProperties = [.read, .write, .notify, .writeWithoutResponse]
            let permissions: CBAttributePermissions = [.readable, .writeable]

            positionChar = CBMutableCharacteristic(
                type: BleAdvertiserChannel.positionCharUUID,
                properties: properties, value: nil, permissions: permissions
            )
            markerChar = CBMutableCharacteristic(
                type: BleAdvertiserChannel.markerCharUUID,
                properties: properties, value: nil, permissions: permissions
            )
            controlChar = CBMutableCharacteristic(
                type: BleAdvertiserChannel.controlCharUUID,
                properties: properties, value: nil, permissions: permissions
            )
            annotationChar = CBMutableCharacteristic(
                type: BleAdvertiserChannel.annotationCharUUID,
                properties: properties, value: nil, permissions: permissions
            )

            let service = CBMutableService(type: BleAdvertiserChannel.serviceUUID, primary: true)
            service.characteristics = [positionChar!, markerChar!, controlChar!, annotationChar!]
            gattService = service

            // Add the service — advertising will start in the didAdd callback
            // once the service is confirmed registered. Starting advertising
            // before didAdd fires can result in the central discovering the
            // UUID but getting an empty/incomplete service on discoverServices().
            pendingStartAdvertising = true
            pm.add(service)
            os_log("GATT service queued for registration", log: log, type: .info)
        } else {
            // Service already registered from a previous call — start directly
            beginAdvertising()
        }
    }

    /// Actually start the BLE advertisement. Called only after the GATT
    /// service has been confirmed registered via `didAdd`.
    ///
    /// CRITICAL: Apple does NOT support `CBAdvertisementDataServiceDataKey`
    /// in `CBPeripheralManager.startAdvertising` for third-party apps —
    /// the documentation is misleading. Passing it causes a SIGABRT in
    /// Apple's XPC serialization with `-[CBUUID UTF8String]: unrecognized
    /// selector` (the inner `[CBUUID: Data]` dict is rejected because
    /// CoreBluetooth's XPC layer only accepts string keys for that
    /// payload). v1.5.4+307 had this and TestFlight crash logs caught it
    /// on iPad / iOS 26.3. Fixed in v1.5.4+308 by reverting to the
    /// Apple-blessed 2-key dict (ServiceUUIDs + optional LocalName).
    ///
    /// The session id is therefore NOT carried in the BLE advertisement
    /// from iOS hosts. iOS-to-iOS discovery falls back to Multipeer
    /// Connectivity (wired in main.dart via MultiTransport), which uses
    /// Bonjour's discoveryInfo to carry the session id. iOS hosts seen
    /// by Android scanners still appear, but `device.sessionId` is null,
    /// so the joiner UI prompts for QR / Manual entry.
    private func beginAdvertising() {
        guard let pm = peripheralManager else { return }

        // Apple's whitelist for `startAdvertising:` is:
        //   - CBAdvertisementDataServiceUUIDsKey  (array of CBUUID)
        //   - CBAdvertisementDataLocalNameKey     (String)
        // Anything else either silently strips OR crashes the XPC layer.
        let advertData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [BleAdvertiserChannel.serviceUUID],
        ]

        // Belt-and-braces guard: if a future change re-introduces a key
        // outside the whitelist (and especially one whose VALUE contains
        // a non-NSString-keyed dict, like CBAdvertisementDataServiceDataKey
        // = [CBUUID: Data]), the XPC serialization in CoreBluetooth will
        // SIGABRT inside `pm.startAdvertising`. Fail loudly during dev/
        // beta builds so the regression is caught before another TestFlight
        // crash report.
        let allowedKeys: Set<String> = [
            CBAdvertisementDataServiceUUIDsKey,
            CBAdvertisementDataLocalNameKey,
        ]
        for k in advertData.keys {
            assert(
                allowedKeys.contains(k),
                """
                BleAdvertiserChannel: advertData contains key '\(k)' which
                is NOT in Apple's documented whitelist for startAdvertising:.
                See v1.5.4+307 TestFlight crash (CBUUID UTF8String).
                """
            )
        }

        pm.startAdvertising(advertData)

        os_log("Advertising started (session=%{public}@)", log: log, type: .info,
               pendingSessionId ?? "nil")
    }

    /// Convert a UUID v4 string ("550e8400-e29b-41d4-a716-446655440000")
    /// into the 16 raw bytes that go into the BLE service data field.
    /// Mirrors `BleConstants.encodeSessionIdToBytes` on the Dart side.
    private static func sessionIdToBytes(_ sessionId: String) -> [UInt8]? {
        let hex = sessionId.replacingOccurrences(of: "-", with: "")
        guard hex.count == 32 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(16)
        var index = hex.startIndex
        for _ in 0..<16 {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        return bytes
    }

    private func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()
        gattService = nil
        positionChar = nil
        markerChar = nil
        controlChar = nil
        annotationChar = nil
        subscribedCentrals.removeAll()
        pendingAdvertise = false
        pendingStartAdvertising = false
        pendingSessionId = nil
        os_log("Advertising stopped", log: log, type: .info)
    }

    // MARK: - Update characteristic (Dart → peripheral → central)

    /// Called from Dart when the sync engine wants to push data to
    /// connected centrals via notify.
    private func updateCharacteristicValue(charUuid: String, data: Data, result: @escaping FlutterResult) {
        guard let pm = peripheralManager else {
            result(FlutterError(code: "NOT_READY", message: "Peripheral manager not initialized", details: nil))
            return
        }

        // CoreBluetooth's CBUUID.uuidString returns UPPERCASE but Dart
        // sends lowercase UUIDs from BleConstants. Normalize both sides.
        let normalizedUuid = charUuid.uppercased()
        let char: CBMutableCharacteristic?
        switch normalizedUuid {
        case BleAdvertiserChannel.positionCharUUID.uuidString.uppercased():
            char = positionChar
        case BleAdvertiserChannel.markerCharUUID.uuidString.uppercased():
            char = markerChar
        case BleAdvertiserChannel.controlCharUUID.uuidString.uppercased():
            char = controlChar
        case BleAdvertiserChannel.annotationCharUUID.uuidString.uppercased():
            char = annotationChar
        default:
            os_log("Unknown characteristic UUID: %{public}@", log: log, type: .error, charUuid)
            result(FlutterError(code: "UNKNOWN_CHAR", message: "Unknown characteristic UUID: \(charUuid)", details: nil))
            return
        }

        guard let characteristic = char else {
            result(FlutterError(code: "NOT_READY", message: "Characteristic not built yet", details: nil))
            return
        }

        let success = pm.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
        os_log("UPDATE VALUE: char=%{public}@ size=%d subs=%d success=%{public}@",
               log: log, type: .error,
               charUuid, data.count, subscribedCentrals.count,
               success ? "YES" : "NO")
        result(success)
    }

    // MARK: - Event helpers

    private func sendEvent(_ eventName: String, data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?([
                "event": eventName,
                "data": data,
            ])
        }
    }
}

// MARK: - FlutterStreamHandler

extension BleAdvertiserChannel: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BleAdvertiserChannel: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        os_log("Peripheral manager state: %d", log: log, type: .info, peripheral.state.rawValue)

        if peripheral.state == .poweredOn && pendingAdvertise {
            pendingAdvertise = false
            buildAndAdvertise()
        }

        sendEvent("onStateChanged", data: [
            "state": peripheral.state.rawValue,
        ])
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            os_log("Advertising failed: %{public}@", log: log, type: .error, error.localizedDescription)
            sendEvent("onError", data: ["message": error.localizedDescription])
        } else {
            os_log("Advertising confirmed", log: log, type: .info)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            os_log("Service add FAILED: %{public}@", log: log, type: .error, error.localizedDescription)
            sendEvent("onError", data: ["message": "Service registration failed: \(error.localizedDescription)"])
        } else {
            os_log("Service registered: %{public}@", log: log, type: .info, service.uuid.uuidString)

            // Service is now confirmed in the GATT database — safe to advertise
            if pendingStartAdvertising {
                pendingStartAdvertising = false
                beginAdvertising()
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didReceiveRead request: CBATTRequest) {
        // Return empty data for read requests — real data flows via notify.
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let data = request.value {
                let charUuid = request.characteristic.uuid.uuidString
                os_log("WRITE RECEIVED on %{public}@ from %{public}@ (%d bytes)",
                       log: log, type: .error,
                       charUuid, request.central.identifier.uuidString, data.count)

                // Forward to Dart via event channel
                sendEvent("onDataReceived", data: [
                    "centralId": request.central.identifier.uuidString,
                    "characteristicUuid": charUuid,
                    "data": FlutterStandardTypedData(bytes: data),
                ])
            }
            peripheral.respond(to: request, withResult: .success)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
        // CRITICAL (v1.5.4+311): include `central.maximumUpdateValueLength`
        // in the event so the Dart side can chunk notify payloads that
        // exceed the negotiated ATT MTU. Default ATT MTU is 23 (20 byte
        // payload). A typical Field Link position payload is 150–250
        // bytes; without chunking, iOS silently truncates the rest and
        // the central receives garbled JSON that fails to decode (the
        // root cause of the iPad-as-host → iPhone-as-joiner regression
        // surfaced in v1.5.4+307…+310 TestFlight reports).
        let maxUpdateLen = central.maximumUpdateValueLength
        os_log("CENTRAL SUBSCRIBED: %{public}@ to %{public}@ maxUpdateLen=%d",
               log: log, type: .error,
               central.identifier.uuidString, characteristic.uuid.uuidString,
               maxUpdateLen)

        if !subscribedCentrals.contains(where: { $0.identifier == central.identifier }) {
            subscribedCentrals.append(central)
        }

        sendEvent("onCentralSubscribed", data: [
            "centralId": central.identifier.uuidString,
            "characteristicUuid": characteristic.uuid.uuidString,
            "maxUpdateLength": maxUpdateLen,
        ])
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFrom characteristic: CBCharacteristic) {
        os_log("Central %{public}@ unsubscribed from %{public}@", log: log, type: .info,
               central.identifier.uuidString, characteristic.uuid.uuidString)

        subscribedCentrals.removeAll { $0.identifier == central.identifier }

        sendEvent("onCentralUnsubscribed", data: [
            "centralId": central.identifier.uuidString,
        ])
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Transmit queue has space again — Dart can retry updateValue calls.
        sendEvent("onReadyToUpdate", data: [:])
    }
}
