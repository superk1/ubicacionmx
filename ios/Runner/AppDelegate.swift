<<<<<<< HEAD
import Flutter
import UIKit

@main
=======
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
>>>>>>> ecfc981d82da3022f13eb346c2e8ccac871e6ff6
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
<<<<<<< HEAD
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
=======
    // Coloca tu API Key aquí
    GMSServices.provideAPIKey("TU_API_KEY_AQUI")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
>>>>>>> ecfc981d82da3022f13eb346c2e8ccac871e6ff6
