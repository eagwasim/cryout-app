import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    if #available(iOS 10.0, *) {
       //UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    } 

    GMSServices.provideAPIKey("AIzaSyCrLmqbKX_XIr6D6IYBLDPAhltVNtOzk-E")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
