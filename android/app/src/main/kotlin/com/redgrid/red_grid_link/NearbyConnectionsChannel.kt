package com.redgrid.red_grid_link

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.*
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Platform channel handler for Android Nearby Connections API.
 *
 * Bridges Dart ↔ Android Nearby Connections using:
 * - MethodChannel "com.redgrid.link/nearby_connections" for RPC calls
 * - EventChannel  "com.redgrid.link/nearby_connections/events" for async events
 *
 * Uses Strategy.P2P_CLUSTER for multi-peer mesh topology (up to 8 devices).
 */
class NearbyConnectionsChannel(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "NearbyConnChannel"
        private const val METHOD_CHANNEL = "com.redgrid.link/nearby_connections"
        private const val EVENT_CHANNEL = "com.redgrid.link/nearby_connections/events"
        private const val SERVICE_ID = "com.redgrid.link.fieldlink"
        private const val PERMISSIONS_REQUEST_CODE = 9001
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private val connectionsClient: ConnectionsClient by lazy {
        Nearby.getConnectionsClient(activity)
    }

    // Track connected endpoints
    private val connectedEndpoints = mutableMapOf<String, String>() // endpointId -> endpointName

    // Track discovered endpoints
    private val discoveredEndpoints = mutableMapOf<String, String>() // endpointId -> endpointName

    // Current session ID for this advertising/discovery session
    private var currentSessionId: String? = null

    // -------------------------------------------------------------------------
    // Registration
    // -------------------------------------------------------------------------

    fun register(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        )
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL,
        )
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(TAG, "EventChannel listener attached")
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                Log.d(TAG, "EventChannel listener detached")
            }
        })

        Log.d(TAG, "NearbyConnectionsChannel registered")
    }

    fun unregister() {
        methodChannel.setMethodCallHandler(null)
        eventSink = null
        stopAllEndpoints()
    }

    // -------------------------------------------------------------------------
    // MethodChannel dispatch
    // -------------------------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startAdvertising" -> startAdvertising(call, result)
            "startDiscovery" -> startDiscovery(call, result)
            "stopAdvertising" -> stopAdvertising(result)
            "stopDiscovery" -> stopDiscovery(result)
            "requestConnection" -> requestConnection(call, result)
            "acceptConnection" -> acceptConnection(call, result)
            "rejectConnection" -> rejectConnection(call, result)
            "disconnectFromEndpoint" -> disconnectFromEndpoint(call, result)
            "stopAllEndpoints" -> {
                stopAllEndpoints()
                result.success(null)
            }
            "sendPayload" -> sendPayload(call, result)
            "getConnectedPeers" -> getConnectedPeers(result)
            else -> result.notImplemented()
        }
    }

    // -------------------------------------------------------------------------
    // Advertising
    // -------------------------------------------------------------------------

    private fun startAdvertising(call: MethodCall, result: MethodChannel.Result) {
        if (!checkPermissions()) {
            result.error("PERMISSION_DENIED", "Required permissions not granted", null)
            return
        }

        val sessionId = call.argument<String>("sessionId")
        val displayName = call.argument<String>("displayName") ?: Build.MODEL
        currentSessionId = sessionId

        val advertisingOptions = AdvertisingOptions.Builder()
            .setStrategy(Strategy.P2P_CLUSTER)
            .build()

        connectionsClient.startAdvertising(
            displayName,
            SERVICE_ID,
            connectionLifecycleCallback,
            advertisingOptions,
        ).addOnSuccessListener {
            Log.d(TAG, "Advertising started (displayName=$displayName, serviceId=$SERVICE_ID)")
            result.success(null)
        }.addOnFailureListener { e ->
            Log.e(TAG, "Failed to start advertising", e)
            result.error(
                "ADVERTISING_FAILED",
                "Failed to start advertising: ${e.message}",
                e.stackTraceToString(),
            )
        }
    }

    private fun stopAdvertising(result: MethodChannel.Result) {
        connectionsClient.stopAdvertising()
        Log.d(TAG, "Advertising stopped")
        result.success(null)
    }

    // -------------------------------------------------------------------------
    // Discovery
    // -------------------------------------------------------------------------

    private fun startDiscovery(call: MethodCall, result: MethodChannel.Result) {
        if (!checkPermissions()) {
            result.error("PERMISSION_DENIED", "Required permissions not granted", null)
            return
        }

        val discoveryOptions = DiscoveryOptions.Builder()
            .setStrategy(Strategy.P2P_CLUSTER)
            .build()

        connectionsClient.startDiscovery(
            SERVICE_ID,
            endpointDiscoveryCallback,
            discoveryOptions,
        ).addOnSuccessListener {
            Log.d(TAG, "Discovery started (serviceId=$SERVICE_ID)")
            result.success(null)
        }.addOnFailureListener { e ->
            Log.e(TAG, "Failed to start discovery", e)
            result.error(
                "DISCOVERY_FAILED",
                "Failed to start discovery: ${e.message}",
                e.stackTraceToString(),
            )
        }
    }

    private fun stopDiscovery(result: MethodChannel.Result) {
        connectionsClient.stopDiscovery()
        discoveredEndpoints.clear()
        Log.d(TAG, "Discovery stopped")
        result.success(null)
    }

    // -------------------------------------------------------------------------
    // Connection management
    // -------------------------------------------------------------------------

    private fun requestConnection(call: MethodCall, result: MethodChannel.Result) {
        val endpointId = call.argument<String>("endpointId")
        if (endpointId == null) {
            result.error("INVALID_ARGS", "endpointId is required", null)
            return
        }

        val displayName = Build.MODEL

        connectionsClient.requestConnection(
            displayName,
            endpointId,
            connectionLifecycleCallback,
        ).addOnSuccessListener {
            Log.d(TAG, "Connection requested to $endpointId")
            result.success(null)
        }.addOnFailureListener { e ->
            Log.e(TAG, "Failed to request connection to $endpointId", e)
            result.error(
                "CONNECTION_FAILED",
                "Failed to request connection: ${e.message}",
                e.stackTraceToString(),
            )
        }
    }

    private fun acceptConnection(call: MethodCall, result: MethodChannel.Result) {
        val endpointId = call.argument<String>("endpointId")
        if (endpointId == null) {
            result.error("INVALID_ARGS", "endpointId is required", null)
            return
        }

        connectionsClient.acceptConnection(endpointId, payloadCallback)
            .addOnSuccessListener {
                Log.d(TAG, "Connection accepted for $endpointId")
                result.success(null)
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to accept connection for $endpointId", e)
                result.error(
                    "ACCEPT_FAILED",
                    "Failed to accept connection: ${e.message}",
                    e.stackTraceToString(),
                )
            }
    }

    private fun rejectConnection(call: MethodCall, result: MethodChannel.Result) {
        val endpointId = call.argument<String>("endpointId")
        if (endpointId == null) {
            result.error("INVALID_ARGS", "endpointId is required", null)
            return
        }

        connectionsClient.rejectConnection(endpointId)
            .addOnSuccessListener {
                Log.d(TAG, "Connection rejected for $endpointId")
                result.success(null)
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to reject connection for $endpointId", e)
                result.error(
                    "REJECT_FAILED",
                    "Failed to reject connection: ${e.message}",
                    e.stackTraceToString(),
                )
            }
    }

    private fun disconnectFromEndpoint(call: MethodCall, result: MethodChannel.Result) {
        val endpointId = call.argument<String>("endpointId")
        if (endpointId == null) {
            result.error("INVALID_ARGS", "endpointId is required", null)
            return
        }

        connectionsClient.disconnectFromEndpoint(endpointId)
        connectedEndpoints.remove(endpointId)
        Log.d(TAG, "Disconnected from $endpointId")
        result.success(null)
    }

    private fun stopAllEndpoints() {
        connectionsClient.stopAllEndpoints()
        connectedEndpoints.clear()
        discoveredEndpoints.clear()
        currentSessionId = null
        Log.d(TAG, "All endpoints stopped")
    }

    // -------------------------------------------------------------------------
    // Data transfer
    // -------------------------------------------------------------------------

    private fun sendPayload(call: MethodCall, result: MethodChannel.Result) {
        val endpointId = call.argument<String>("endpointId")
        val bytes = call.argument<ByteArray>("bytes")

        if (endpointId == null || bytes == null) {
            result.error("INVALID_ARGS", "endpointId and bytes are required", null)
            return
        }

        if (!connectedEndpoints.containsKey(endpointId)) {
            result.error(
                "NOT_CONNECTED",
                "Endpoint $endpointId is not connected",
                null,
            )
            return
        }

        val payload = Payload.fromBytes(bytes)

        connectionsClient.sendPayload(endpointId, payload)
            .addOnSuccessListener {
                Log.d(TAG, "Payload sent to $endpointId (${bytes.size} bytes)")
                result.success(null)
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to send payload to $endpointId", e)
                result.error(
                    "SEND_FAILED",
                    "Failed to send payload: ${e.message}",
                    e.stackTraceToString(),
                )
            }
    }

    private fun getConnectedPeers(result: MethodChannel.Result) {
        val peers = connectedEndpoints.map { (id, name) ->
            mapOf("endpointId" to id, "endpointName" to name)
        }
        result.success(peers)
    }

    // -------------------------------------------------------------------------
    // Nearby Connections callbacks
    // -------------------------------------------------------------------------

    /**
     * Called when nearby endpoints are discovered or lost.
     */
    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            Log.d(TAG, "Endpoint found: $endpointId (${info.endpointName})")
            discoveredEndpoints[endpointId] = info.endpointName

            sendEvent("onEndpointFound", mapOf(
                "endpointId" to endpointId,
                "endpointName" to info.endpointName,
                "serviceId" to info.serviceId,
            ))
        }

        override fun onEndpointLost(endpointId: String) {
            Log.d(TAG, "Endpoint lost: $endpointId")
            discoveredEndpoints.remove(endpointId)

            sendEvent("onEndpointLost", mapOf(
                "endpointId" to endpointId,
            ))
        }
    }

    /**
     * Called during the connection lifecycle: initiation, result, disconnection.
     */
    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, info: ConnectionInfo) {
            Log.d(TAG, "Connection initiated: $endpointId (${info.endpointName})")

            sendEvent("onConnectionInitiated", mapOf(
                "endpointId" to endpointId,
                "endpointName" to info.endpointName,
                "authenticationDigits" to info.authenticationDigits,
                "isIncomingConnection" to info.isIncomingConnection,
            ))
        }

        override fun onConnectionResult(endpointId: String, resolution: ConnectionResolution) {
            val success = resolution.status.isSuccess
            Log.d(TAG, "Connection result for $endpointId: success=$success (status=${resolution.status.statusCode})")

            if (success) {
                val name = discoveredEndpoints[endpointId] ?: "Unknown"
                connectedEndpoints[endpointId] = name
            }

            sendEvent("onConnectionResult", mapOf(
                "endpointId" to endpointId,
                "success" to success,
                "statusCode" to resolution.status.statusCode,
            ))
        }

        override fun onDisconnected(endpointId: String) {
            Log.d(TAG, "Disconnected from $endpointId")
            connectedEndpoints.remove(endpointId)

            sendEvent("onDisconnected", mapOf(
                "endpointId" to endpointId,
            ))
        }
    }

    /**
     * Called when payloads (byte arrays) are received from connected endpoints.
     */
    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            if (payload.type == Payload.Type.BYTES) {
                val bytes = payload.asBytes()
                if (bytes != null) {
                    Log.d(TAG, "Payload received from $endpointId (${bytes.size} bytes)")
                    sendEvent("onPayloadReceived", mapOf(
                        "endpointId" to endpointId,
                        "bytes" to bytes,
                    ))
                }
            } else {
                Log.w(TAG, "Received non-BYTES payload from $endpointId (type=${payload.type}), ignoring")
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            // For BYTES payloads, transfer is instantaneous.
            // Only relevant for STREAM or FILE payloads, which we don't use.
            if (update.status == PayloadTransferUpdate.Status.FAILURE) {
                Log.w(TAG, "Payload transfer failed for $endpointId (payloadId=${update.payloadId})")
            }
        }
    }

    // -------------------------------------------------------------------------
    // Event helpers
    // -------------------------------------------------------------------------

    /**
     * Send an event to the Dart side via the EventChannel.
     */
    private fun sendEvent(eventName: String, data: Map<String, Any?>) {
        activity.runOnUiThread {
            eventSink?.success(mapOf(
                "event" to eventName,
                "data" to data,
            ))
        }
    }

    // -------------------------------------------------------------------------
    // Permissions
    // -------------------------------------------------------------------------

    /**
     * Check if the required permissions for Nearby Connections are granted.
     *
     * On Android 12+ (API 31+), Bluetooth scan/advertise/connect permissions
     * are required. On older versions, fine location is sufficient.
     */
    private fun checkPermissions(): Boolean {
        val requiredPermissions = mutableListOf<String>()

        // Location is always required for Nearby Connections
        requiredPermissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
        requiredPermissions.add(Manifest.permission.ACCESS_COARSE_LOCATION)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ requires explicit BT permissions
            requiredPermissions.add(Manifest.permission.BLUETOOTH_SCAN)
            requiredPermissions.add(Manifest.permission.BLUETOOTH_ADVERTISE)
            requiredPermissions.add(Manifest.permission.BLUETOOTH_CONNECT)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ for nearby WiFi
            requiredPermissions.add(Manifest.permission.NEARBY_WIFI_DEVICES)
        }

        val missingPermissions = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isNotEmpty()) {
            Log.w(TAG, "Missing permissions: $missingPermissions")
            ActivityCompat.requestPermissions(
                activity,
                missingPermissions.toTypedArray(),
                PERMISSIONS_REQUEST_CODE,
            )
            return false
        }

        return true
    }
}
