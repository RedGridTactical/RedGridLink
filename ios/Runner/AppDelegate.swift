import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    private var multipeerChannel: MultipeerChannel?
    private var batteryChannel: BatteryChannel?
    private var bleAdvertiserChannel: BleAdvertiserChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        // Access the binary messenger through the application registrar
        let messenger = engineBridge.applicationRegistrar.messenger()

        // Register Multipeer Connectivity platform channel
        multipeerChannel = MultipeerChannel()
        multipeerChannel?.register(with: messenger)

        // Register Battery platform channel
        batteryChannel = BatteryChannel()
        batteryChannel?.register(with: messenger)

        // Register BLE PHY platform channel (Coded PHY / Long Range)
        BlePhyChannel.register(with: messenger)

        // Register BLE Advertiser platform channel (GATT server / peripheral mode)
        bleAdvertiserChannel = BleAdvertiserChannel()
        bleAdvertiserChannel?.register(with: messenger)
    }
}
