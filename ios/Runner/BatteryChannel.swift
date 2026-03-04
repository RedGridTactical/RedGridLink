import Flutter
import Foundation
import UIKit
import os.log

/// Platform channel handler for battery information on iOS.
///
/// Provides battery level and charging state to the Dart side via
/// FlutterMethodChannel "com.redgrid.link/battery".
///
/// Used by Field Link to include battery info in peer status broadcasts
/// and to enable battery-aware expedition mode.
class BatteryChannel: NSObject {

    // MARK: - Constants

    private static let methodChannelName = "com.redgrid.link/battery"

    private let log = OSLog(subsystem: "com.redgrid.link", category: "BatteryChannel")

    // MARK: - Flutter channel

    private var methodChannel: FlutterMethodChannel?

    // MARK: - Registration

    func register(with messenger: FlutterBinaryMessenger) {
        // Enable battery monitoring so UIDevice reports meaningful values
        UIDevice.current.isBatteryMonitoringEnabled = true

        methodChannel = FlutterMethodChannel(
            name: BatteryChannel.methodChannelName,
            binaryMessenger: messenger
        )
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }

        os_log("BatteryChannel registered", log: log, type: .info)
    }

    func unregister() {
        methodChannel?.setMethodCallHandler(nil)
        methodChannel = nil
    }

    // MARK: - Method dispatch

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getBatteryLevel":
            getBatteryLevel(result: result)
        case "getBatteryState":
            getBatteryState(result: result)
        case "getBatteryInfo":
            getBatteryInfo(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Battery level

    /// Returns the current battery level as an integer percentage (0-100).
    /// Returns -1 if the battery level cannot be determined (e.g., on Simulator).
    private func getBatteryLevel(result: @escaping FlutterResult) {
        let level = UIDevice.current.batteryLevel
        if level < 0 {
            // -1.0 means battery level is unknown (e.g., Simulator)
            result(-1)
        } else {
            result(Int(level * 100))
        }
    }

    // MARK: - Battery state

    /// Returns the current battery charging state as a string:
    /// - "charging"
    /// - "discharging" (mapped from .unplugged)
    /// - "full"
    /// - "unknown"
    private func getBatteryState(result: @escaping FlutterResult) {
        let state = UIDevice.current.batteryState
        result(batteryStateString(state))
    }

    private func batteryStateString(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .charging:
            return "charging"
        case .unplugged:
            return "discharging"
        case .full:
            return "full"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }

    // MARK: - Combined battery info

    /// Returns a map with both level and state for efficiency.
    private func getBatteryInfo(result: @escaping FlutterResult) {
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState

        let levelInt = level < 0 ? -1 : Int(level * 100)

        result([
            "level": levelInt,
            "state": batteryStateString(state),
            // iOS doesn't expose battery temperature via public APIs
            "temperature": -1.0,
        ] as [String: Any])
    }
}
