package com.redgrid.red_grid_link

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Platform channel handler for battery information.
 *
 * Provides battery level and charging state to the Dart side via
 * MethodChannel "com.redgrid.link/battery".
 *
 * Used by Field Link to include battery info in peer status broadcasts
 * and to enable battery-aware expedition mode.
 */
class BatteryChannel(
    private val context: Context,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "BatteryChannel"
        private const val METHOD_CHANNEL = "com.redgrid.link/battery"
    }

    private lateinit var methodChannel: MethodChannel

    // -------------------------------------------------------------------------
    // Registration
    // -------------------------------------------------------------------------

    fun register(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        )
        methodChannel.setMethodCallHandler(this)
        Log.d(TAG, "BatteryChannel registered")
    }

    fun unregister() {
        methodChannel.setMethodCallHandler(null)
    }

    // -------------------------------------------------------------------------
    // MethodChannel dispatch
    // -------------------------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getBatteryLevel" -> getBatteryLevel(result)
            "getBatteryState" -> getBatteryState(result)
            "getBatteryInfo" -> getBatteryInfo(result)
            else -> result.notImplemented()
        }
    }

    // -------------------------------------------------------------------------
    // Battery level
    // -------------------------------------------------------------------------

    /**
     * Returns the current battery level as an integer percentage (0-100).
     * Returns -1 if the battery level cannot be determined.
     */
    private fun getBatteryLevel(result: MethodChannel.Result) {
        try {
            val level = getBatteryLevelInternal()
            result.success(level)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get battery level", e)
            result.error(
                "BATTERY_ERROR",
                "Failed to get battery level: ${e.message}",
                null,
            )
        }
    }

    private fun getBatteryLevelInternal(): Int {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        if (batteryManager != null) {
            return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        }

        // Fallback: read from sticky broadcast
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        if (intent != null) {
            val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            if (level >= 0 && scale > 0) {
                return (level * 100) / scale
            }
        }

        return -1
    }

    // -------------------------------------------------------------------------
    // Battery state
    // -------------------------------------------------------------------------

    /**
     * Returns the current battery charging state as a string:
     * - "charging"
     * - "discharging"
     * - "full"
     * - "not_charging"
     * - "unknown"
     */
    private fun getBatteryState(result: MethodChannel.Result) {
        try {
            val state = getBatteryStateInternal()
            result.success(state)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get battery state", e)
            result.error(
                "BATTERY_ERROR",
                "Failed to get battery state: ${e.message}",
                null,
            )
        }
    }

    private fun getBatteryStateInternal(): String {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        if (intent == null) return "unknown"

        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        return when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
            BatteryManager.BATTERY_STATUS_FULL -> "full"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "not_charging"
            else -> "unknown"
        }
    }

    // -------------------------------------------------------------------------
    // Combined battery info
    // -------------------------------------------------------------------------

    /**
     * Returns a map with both level and state for efficiency
     * (single call from Dart instead of two).
     */
    private fun getBatteryInfo(result: MethodChannel.Result) {
        try {
            val level = getBatteryLevelInternal()
            val state = getBatteryStateInternal()

            val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val temperature = if (intent != null) {
                intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) / 10.0
            } else {
                -1.0
            }

            result.success(mapOf(
                "level" to level,
                "state" to state,
                "temperature" to temperature,
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get battery info", e)
            result.error(
                "BATTERY_ERROR",
                "Failed to get battery info: ${e.message}",
                null,
            )
        }
    }
}
