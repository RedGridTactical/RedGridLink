import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    private var multipeerChannel: MultipeerChannel?
    private var batteryChannel: BatteryChannel?

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
    }
}
