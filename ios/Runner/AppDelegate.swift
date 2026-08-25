import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ‼️ **المفتاح من Info.plist لا من الشيفرة.** كتابته هنا تُودعه المستودع،
    //    والقيمة تُحقن عند البناء (Codemagic) في مفتاح `MAPS_API_KEY`.
    //    وغيابه لا يُسقط التطبيق — الخريطة وحدها تبقى رماديّة.
    if let key = Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String,
       !key.isEmpty {
      GMSServices.provideAPIKey(key)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
