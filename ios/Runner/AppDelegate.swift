import Flutter
import UIKit

private var firebaseAvailable = false

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      if let firebaseClass = NSClassFromString("FIRApp") as? NSObject.Type {
        firebaseClass.perform(NSSelectorFromString("configure"))
        firebaseAvailable = true
      }
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    if firebaseAvailable {
      if let messagingClass = NSClassFromString("FIRMessaging") as? NSObject.Type {
        let sel = NSSelectorFromString("messaging")
        if let messaging = messagingClass.perform(sel)?.takeUnretainedValue() as? NSObject {
          messaging.setValue(deviceToken, forKey: "APNSToken")
        }
      }
    }
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
  }
}
