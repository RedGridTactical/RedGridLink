import Flutter
import CoreBluetooth

/// Platform channel for BLE Coded PHY (Long Range) support detection.
///
/// On iOS 14+, CoreBluetooth automatically negotiates Coded PHY when both
/// devices support it. This channel reports capability, not explicit PHY selection.
class BlePhyChannel: NSObject {
    static let channelName = "com.redgrid.link/ble_phy"

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        let instance = BlePhyChannel()
        channel.setMethodCallHandler(instance.handle)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isCodedPhySupported":
            // iOS auto-negotiates Coded PHY on iPhone 8+ with iOS 14+
            if #available(iOS 14.0, *) {
                result(true)
            } else {
                result(false)
            }
        case "requestCodedPhy":
            // iOS handles PHY negotiation automatically — confirm capability
            if #available(iOS 14.0, *) {
                result(true)
            } else {
                result(false)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
