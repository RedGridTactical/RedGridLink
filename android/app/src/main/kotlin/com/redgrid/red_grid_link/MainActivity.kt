package com.redgrid.red_grid_link

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val MAIN_CHANNEL = "com.redgrid.link/main"
    }

    private var nearbyConnectionsChannel: NearbyConnectionsChannel? = null
    private var batteryChannel: BatteryChannel? = null
    private var mainMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register Nearby Connections platform channel
        nearbyConnectionsChannel = NearbyConnectionsChannel(this).also {
            it.register(flutterEngine)
        }

        // Register Battery platform channel
        batteryChannel = BatteryChannel(this).also {
            it.register(flutterEngine)
        }

        // Register main method channel (foreground service control)
        mainMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MAIN_CHANNEL,
        ).also {
            it.setMethodCallHandler { call, result ->
                handleMainMethodCall(call, result)
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        nearbyConnectionsChannel?.unregister()
        nearbyConnectionsChannel = null

        batteryChannel?.unregister()
        batteryChannel = null

        mainMethodChannel?.setMethodCallHandler(null)
        mainMethodChannel = null

        super.cleanUpFlutterEngine(flutterEngine)
    }

    // -------------------------------------------------------------------------
    // Main method channel — foreground service control
    // -------------------------------------------------------------------------

    private fun handleMainMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startForegroundService" -> {
                val peerCount = call.argument<Int>("peerCount") ?: 0
                val intent = Intent(this, FieldLinkForegroundService::class.java).apply {
                    putExtra(FieldLinkForegroundService.EXTRA_PEER_COUNT, peerCount)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
                result.success(true)
            }
            "stopForegroundService" -> {
                val intent = Intent(this, FieldLinkForegroundService::class.java).apply {
                    action = FieldLinkForegroundService.ACTION_STOP
                }
                startService(intent)
                result.success(true)
            }
            "updateNotification" -> {
                val peerCount = call.argument<Int>("peerCount") ?: 0
                val intent = Intent(this, FieldLinkForegroundService::class.java).apply {
                    putExtra(FieldLinkForegroundService.EXTRA_PEER_COUNT, peerCount)
                }
                startService(intent)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
