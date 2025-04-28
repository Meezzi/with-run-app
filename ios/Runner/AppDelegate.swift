import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let mapsChannel = FlutterMethodChannel(name: "com.example.with_run_app/maps", binaryMessenger: controller.binaryMessenger)
    mapsChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "initGoogleMaps" {
        if let args = call.arguments as? [String: String], let apiKey = args["apiKey"] {
          GMSServices.provideAPIKey(apiKey)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_KEY", message: "API Key missing", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}