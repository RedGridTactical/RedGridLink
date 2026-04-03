package com.redgrid.red_grid_link

import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Platform channel for BLE Coded PHY (Long Range) support detection.
 *
 * On Android 8.0+ (API 26), checks if the Bluetooth adapter supports
 * LE Coded PHY for extended range (400m-1km vs ~50m standard BLE).
 *
 * NOTE: Actual PHY negotiation (setPreferredPhy) is handled by
 * flutter_blue_plus on the Dart side via BluetoothDevice.setPreferredPhy().
 * This channel is only used for checking hardware support.
 */
class BlePhyChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.redgrid.link/ble_phy"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isCodedPhySupported" -> {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                    result.success(false)
                    return
                }
                val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                val adapter = manager?.adapter
                result.success(adapter?.isLeCodedPhySupported == true)
            }
            "requestCodedPhy" -> {
                // Coded PHY negotiation happens at the GATT level.
                // flutter_blue_plus manages GATT connections internally.
                // This method reports whether the platform supports requesting it.
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                    result.success(false)
                    return
                }
                val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                val adapter = manager?.adapter
                result.success(adapter?.isLeCodedPhySupported == true)
            }
            else -> result.notImplemented()
        }
    }
}
