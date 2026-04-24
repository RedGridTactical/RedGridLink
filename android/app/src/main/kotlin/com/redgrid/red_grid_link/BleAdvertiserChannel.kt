package com.redgrid.red_grid_link

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/**
 * Platform channel handler for BLE peripheral-mode advertising.
 *
 * Uses [BluetoothGattServer] to advertise the Field Link GATT service so
 * that central-mode scanners (the joiners) can discover the session host.
 *
 * The GATT service contains four characteristics matching the central-
 * mode subscription UUIDs in BleConstants:
 *   - position   (read + notify + write)
 *   - marker     (read + notify + write)
 *   - control    (read + notify + write)
 *   - annotation (read + notify + write)
 *
 * Incoming writes from connected centrals are forwarded to Dart via an
 * EventChannel so the sync engine can process them identically to data
 * received in central mode.
 *
 * Method channel: com.redgrid.link/ble_advertiser
 * Event channel:  com.redgrid.link/ble_advertiser/events
 */
class BleAdvertiserChannel(
    private val context: Context,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val TAG = "BleAdvertiser"
        private const val METHOD_CHANNEL = "com.redgrid.link/ble_advertiser"
        private const val EVENT_CHANNEL = "com.redgrid.link/ble_advertiser/events"

        /** Must match BleConstants.fieldLinkServiceUuid on the Dart side. */
        private val SERVICE_UUID =
            UUID.fromString("a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d")

        /** Characteristic UUIDs — must match BleConstants on the Dart side. */
        private val POSITION_CHAR_UUID =
            UUID.fromString("a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5e")
        private val MARKER_CHAR_UUID =
            UUID.fromString("a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5f")
        private val CONTROL_CHAR_UUID =
            UUID.fromString("a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c60")
        private val ANNOTATION_CHAR_UUID =
            UUID.fromString("a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c61")

        /** Standard CCCD UUID for notification subscription. */
        private val CCCD_UUID =
            UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }

    // -------------------------------------------------------------------------
    // Flutter channels
    // -------------------------------------------------------------------------

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    // -------------------------------------------------------------------------
    // Bluetooth state
    // -------------------------------------------------------------------------

    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private var gattServer: BluetoothGattServer? = null

    private var positionChar: BluetoothGattCharacteristic? = null
    private var markerChar: BluetoothGattCharacteristic? = null
    private var controlChar: BluetoothGattCharacteristic? = null
    private var annotationChar: BluetoothGattCharacteristic? = null

    /** Devices currently connected to our GATT server. */
    private val connectedDevices = mutableSetOf<BluetoothDevice>()

    private var isAdvertising = false
    private var pendingSessionId: String? = null

    // -------------------------------------------------------------------------
    // Registration
    // -------------------------------------------------------------------------

    fun register(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).also {
            it.setMethodCallHandler(this)
        }

        eventChannel = EventChannel(messenger, EVENT_CHANNEL).also {
            it.setStreamHandler(this)
        }

        bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter

        Log.i(TAG, "BleAdvertiserChannel registered")
    }

    fun unregister() {
        stopAdvertising()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        eventSink = null
    }

    // -------------------------------------------------------------------------
    // EventChannel.StreamHandler
    // -------------------------------------------------------------------------

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // -------------------------------------------------------------------------
    // Method dispatch
    // -------------------------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startAdvertising" -> {
                val sessionId = call.argument<String>("sessionId")
                if (sessionId == null) {
                    result.error("INVALID_ARGS", "sessionId required", null)
                    return
                }
                startAdvertising(sessionId, result)
            }
            "stopAdvertising" -> {
                stopAdvertising()
                result.success(null)
            }
            "updateValue" -> {
                val charUuid = call.argument<String>("characteristicUuid")
                val data = call.argument<ByteArray>("data")
                if (charUuid == null || data == null) {
                    result.error(
                        "INVALID_ARGS",
                        "characteristicUuid and data required",
                        null,
                    )
                    return
                }
                updateCharacteristicValue(charUuid, data, result)
            }
            else -> result.notImplemented()
        }
    }

    // -------------------------------------------------------------------------
    // Advertising
    // -------------------------------------------------------------------------

    private fun startAdvertising(sessionId: String, result: MethodChannel.Result) {
        pendingSessionId = sessionId

        // Check BLUETOOTH_ADVERTISE permission on API 31+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_ADVERTISE)
                != PackageManager.PERMISSION_GRANTED
            ) {
                Log.w(TAG, "BLUETOOTH_ADVERTISE permission not granted")
                result.error(
                    "PERMISSION_DENIED",
                    "BLUETOOTH_ADVERTISE permission required",
                    null,
                )
                return
            }
        }

        val adapter = bluetoothAdapter
        if (adapter == null || !adapter.isEnabled) {
            Log.w(TAG, "Bluetooth adapter not available or disabled")
            result.error("NOT_READY", "Bluetooth not available or disabled", null)
            return
        }

        advertiser = adapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            Log.w(TAG, "BLE advertising not supported on this device")
            result.error(
                "NOT_SUPPORTED",
                "BLE advertising not supported",
                null,
            )
            return
        }

        // Open GATT server and build the service
        buildAndAdvertise()
        result.success(null)
    }

    @Suppress("MissingPermission")
    private fun buildAndAdvertise() {
        val manager = bluetoothManager ?: return

        // Open GATT server if not already open
        if (gattServer == null) {
            gattServer = manager.openGattServer(context, gattServerCallback)
            if (gattServer == null) {
                Log.e(TAG, "Failed to open GATT server")
                sendEvent("onError", mapOf("message" to "Failed to open GATT server"))
                return
            }
        }

        // Build GATT service with 4 characteristics
        val properties =
            BluetoothGattCharacteristic.PROPERTY_READ or
                BluetoothGattCharacteristic.PROPERTY_WRITE or
                BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE or
                BluetoothGattCharacteristic.PROPERTY_NOTIFY

        val permissions =
            BluetoothGattCharacteristic.PERMISSION_READ or
                BluetoothGattCharacteristic.PERMISSION_WRITE

        positionChar = createCharacteristic(POSITION_CHAR_UUID, properties, permissions)
        markerChar = createCharacteristic(MARKER_CHAR_UUID, properties, permissions)
        controlChar = createCharacteristic(CONTROL_CHAR_UUID, properties, permissions)
        annotationChar = createCharacteristic(ANNOTATION_CHAR_UUID, properties, permissions)

        val service = BluetoothGattService(
            SERVICE_UUID,
            BluetoothGattService.SERVICE_TYPE_PRIMARY,
        )
        service.addCharacteristic(positionChar)
        service.addCharacteristic(markerChar)
        service.addCharacteristic(controlChar)
        service.addCharacteristic(annotationChar)

        val added = gattServer?.addService(service) ?: false
        if (!added) {
            Log.e(TAG, "Failed to add GATT service")
            sendEvent("onError", mapOf("message" to "Failed to add GATT service"))
        } else {
            Log.i(TAG, "GATT service queued for registration")
        }

        // Start BLE advertisement
        beginAdvertising()
    }

    /**
     * Creates a characteristic with a CCCD descriptor for notification
     * subscription support.
     */
    private fun createCharacteristic(
        uuid: UUID,
        properties: Int,
        permissions: Int,
    ): BluetoothGattCharacteristic {
        val characteristic = BluetoothGattCharacteristic(uuid, properties, permissions)

        // Add CCCD for notification subscription
        val cccd = BluetoothGattDescriptor(
            CCCD_UUID,
            BluetoothGattDescriptor.PERMISSION_READ or
                BluetoothGattDescriptor.PERMISSION_WRITE,
        )
        characteristic.addDescriptor(cccd)

        return characteristic
    }

    @Suppress("MissingPermission")
    private fun beginAdvertising() {
        val adv = advertiser ?: return

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()

        // Encode the session UUID v4 as 16 raw bytes and put it in the
        // scan-response service-data payload. Joiners parse this from
        // `ScanResult.advertisementData.serviceData` and use it as the
        // canonical CRDT session id. Without this, the join button would
        // call FieldLinkService.joinSession(device.id) where device.id is
        // the BLE peripheral MAC address, which mismatches the host's
        // UUID v4 sessionId and silently breaks sync. (Was the cause of
        // multiple post-v1.5.2 reviewer reports of "phones can't find
        // each other in active sessions".)
        //
        // Falls back to the legacy "RGL" tag if the sessionId is unparseable
        // so we do not hard-fail advertising on a corrupt session id.
        val sessionBytes = pendingSessionId?.let { sessionIdToBytes(it) }
            ?: "RGL".toByteArray()
        val scanResponse = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceData(ParcelUuid(SERVICE_UUID), sessionBytes)
            .build()

        adv.startAdvertising(settings, data, scanResponse, advertiseCallback)
        Log.i(TAG, "Advertising started (session=$pendingSessionId)")
    }

    /**
     * Convert a UUID v4 string ("550e8400-e29b-41d4-a716-446655440000")
     * into the 16 raw bytes that go into the BLE service data field.
     * Mirrors `BleConstants.encodeSessionIdToBytes` on the Dart side and
     * `BleAdvertiserChannel.sessionIdToBytes` on iOS.
     *
     * Returns null if the input is not a parseable hex UUID.
     */
    private fun sessionIdToBytes(sessionId: String): ByteArray? {
        val hex = sessionId.replace("-", "")
        if (hex.length != 32) return null
        return try {
            ByteArray(16) { i ->
                hex.substring(i * 2, i * 2 + 2).toInt(16).toByte()
            }
        } catch (e: NumberFormatException) {
            null
        }
    }

    @Suppress("MissingPermission")
    private fun stopAdvertising() {
        try {
            advertiser?.stopAdvertising(advertiseCallback)
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping advertising: ${e.message}")
        }

        try {
            gattServer?.clearServices()
            gattServer?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing GATT server: ${e.message}")
        }

        gattServer = null
        positionChar = null
        markerChar = null
        controlChar = null
        annotationChar = null
        connectedDevices.clear()
        isAdvertising = false
        pendingSessionId = null

        Log.i(TAG, "Advertising stopped")
    }

    // -------------------------------------------------------------------------
    // Update characteristic (Dart -> peripheral -> central)
    // -------------------------------------------------------------------------

    /**
     * Called from Dart when the sync engine wants to push data to
     * connected centrals via notify.
     */
    @Suppress("MissingPermission")
    private fun updateCharacteristicValue(
        charUuid: String,
        data: ByteArray,
        result: MethodChannel.Result,
    ) {
        val server = gattServer
        if (server == null) {
            result.error("NOT_READY", "GATT server not initialized", null)
            return
        }

        // Android uses lowercase UUIDs; normalize for comparison.
        val normalizedUuid = charUuid.lowercase()
        val characteristic: BluetoothGattCharacteristic? = when (normalizedUuid) {
            POSITION_CHAR_UUID.toString().lowercase() -> positionChar
            MARKER_CHAR_UUID.toString().lowercase() -> markerChar
            CONTROL_CHAR_UUID.toString().lowercase() -> controlChar
            ANNOTATION_CHAR_UUID.toString().lowercase() -> annotationChar
            else -> {
                Log.e(TAG, "Unknown characteristic UUID: $charUuid")
                result.error(
                    "UNKNOWN_CHAR",
                    "Unknown characteristic UUID: $charUuid",
                    null,
                )
                return
            }
        }

        if (characteristic == null) {
            result.error("NOT_READY", "Characteristic not built yet", null)
            return
        }

        // Set the value on the characteristic, then notify each connected device
        characteristic.value = data
        var allSuccess = true
        for (device in connectedDevices) {
            try {
                val sent = server.notifyCharacteristicChanged(
                    device,
                    characteristic,
                    false, // confirm = false -> notification (not indication)
                )
                if (!sent) {
                    allSuccess = false
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to notify device ${device.address}: ${e.message}")
                allSuccess = false
            }
        }

        Log.d(
            TAG,
            "UPDATE VALUE: char=$charUuid size=${data.size} " +
                "devices=${connectedDevices.size} success=$allSuccess",
        )
        result.success(allSuccess)
    }

    // -------------------------------------------------------------------------
    // AdvertiseCallback
    // -------------------------------------------------------------------------

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            isAdvertising = true
            Log.i(TAG, "Advertising confirmed")
        }

        override fun onStartFailure(errorCode: Int) {
            isAdvertising = false
            val message = when (errorCode) {
                ADVERTISE_FAILED_DATA_TOO_LARGE -> "Data too large"
                ADVERTISE_FAILED_TOO_MANY_ADVERTISERS -> "Too many advertisers"
                ADVERTISE_FAILED_ALREADY_STARTED -> "Already started"
                ADVERTISE_FAILED_INTERNAL_ERROR -> "Internal error"
                ADVERTISE_FAILED_FEATURE_UNSUPPORTED -> "Feature unsupported"
                else -> "Unknown error ($errorCode)"
            }
            Log.e(TAG, "Advertising failed: $message")
            sendEvent("onError", mapOf("message" to "Advertising failed: $message"))
        }
    }

    // -------------------------------------------------------------------------
    // BluetoothGattServerCallback
    // -------------------------------------------------------------------------

    @Suppress("MissingPermission")
    private val gattServerCallback = object : BluetoothGattServerCallback() {

        override fun onConnectionStateChange(
            device: BluetoothDevice,
            status: Int,
            newState: Int,
        ) {
            val address = device.address
            Log.i(TAG, "Connection state change: device=$address state=$newState")

            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    connectedDevices.add(device)
                    sendEvent("onCentralSubscribed", mapOf(
                        "centralId" to address,
                        "characteristicUuid" to SERVICE_UUID.toString(),
                    ))
                    sendEvent("onStateChanged", mapOf("state" to newState))
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    connectedDevices.remove(device)
                    sendEvent("onCentralUnsubscribed", mapOf(
                        "centralId" to address,
                    ))
                    sendEvent("onStateChanged", mapOf("state" to newState))
                }
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?,
        ) {
            val charUuid = characteristic.uuid.toString()
            Log.d(
                TAG,
                "WRITE RECEIVED on $charUuid from ${device.address} " +
                    "(${value?.size ?: 0} bytes)",
            )

            if (value != null) {
                // Forward to Dart via event channel
                sendEvent("onDataReceived", mapOf(
                    "centralId" to device.address,
                    "characteristicUuid" to charUuid,
                    "data" to value,
                ))
            }

            // Send success response if the client expects one
            if (responseNeeded) {
                gattServer?.sendResponse(
                    device,
                    requestId,
                    android.bluetooth.BluetoothGatt.GATT_SUCCESS,
                    offset,
                    value,
                )
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic,
        ) {
            // Return empty data for read requests -- real data flows via notify.
            gattServer?.sendResponse(
                device,
                requestId,
                android.bluetooth.BluetoothGatt.GATT_SUCCESS,
                offset,
                byteArrayOf(),
            )
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?,
        ) {
            // Handle CCCD writes for notification subscription
            if (descriptor.uuid == CCCD_UUID) {
                val charUuid = descriptor.characteristic?.uuid?.toString() ?: "unknown"

                if (value != null && value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)) {
                    Log.d(TAG, "CENTRAL SUBSCRIBED: ${device.address} to $charUuid")
                    connectedDevices.add(device)
                    sendEvent("onCentralSubscribed", mapOf(
                        "centralId" to device.address,
                        "characteristicUuid" to charUuid,
                    ))
                } else if (value != null && value.contentEquals(BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE)) {
                    Log.d(TAG, "Central ${device.address} unsubscribed from $charUuid")
                    sendEvent("onCentralUnsubscribed", mapOf(
                        "centralId" to device.address,
                    ))
                }
            }

            if (responseNeeded) {
                gattServer?.sendResponse(
                    device,
                    requestId,
                    android.bluetooth.BluetoothGatt.GATT_SUCCESS,
                    offset,
                    value,
                )
            }
        }

        override fun onDescriptorReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            descriptor: BluetoothGattDescriptor,
        ) {
            if (descriptor.uuid == CCCD_UUID) {
                // Return current notification state
                gattServer?.sendResponse(
                    device,
                    requestId,
                    android.bluetooth.BluetoothGatt.GATT_SUCCESS,
                    offset,
                    BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE,
                )
            } else {
                gattServer?.sendResponse(
                    device,
                    requestId,
                    android.bluetooth.BluetoothGatt.GATT_SUCCESS,
                    offset,
                    byteArrayOf(),
                )
            }
        }

        override fun onNotificationSent(device: BluetoothDevice, status: Int) {
            Log.d(TAG, "Notification sent to ${device.address}, status=$status")
            if (status == android.bluetooth.BluetoothGatt.GATT_SUCCESS) {
                sendEvent("onReadyToUpdate", emptyMap())
            }
        }

        override fun onServiceAdded(status: Int, service: BluetoothGattService?) {
            if (status == android.bluetooth.BluetoothGatt.GATT_SUCCESS) {
                Log.i(TAG, "Service registered: ${service?.uuid}")
            } else {
                Log.e(TAG, "Service add FAILED, status=$status")
                sendEvent(
                    "onError",
                    mapOf("message" to "Service registration failed (status=$status)"),
                )
            }
        }
    }

    // -------------------------------------------------------------------------
    // Event helpers
    // -------------------------------------------------------------------------

    private fun sendEvent(eventName: String, data: Map<String, Any>) {
        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        handler.post {
            eventSink?.success(mapOf(
                "event" to eventName,
                "data" to data,
            ))
        }
    }
}
