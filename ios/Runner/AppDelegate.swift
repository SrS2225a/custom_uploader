import Flutter
import UIKit
import flutter_sharing_intent

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    let sharingIntent = SwiftFlutterSharingIntentPlugin.instance

    // If the URL matches the plugin's scheme, handle it
    if sharingIntent.hasSameSchemePrefix(url: url) {
        return sharingIntent.application(app, open: url, options: options)
    }

    // Otherwise, forward to other handlers (e.g., uni_links)
    return super.application(app, open: url, options: options)
  }
}

