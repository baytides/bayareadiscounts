import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up method channel for iMessage extension data sharing
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "org.baytides.baynavigator/imessage",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "syncFavorites":
        if let args = call.arguments as? [[String: Any]] {
          self?.syncFavoritesToAppGroup(programs: args)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Expected list of programs", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func syncFavoritesToAppGroup(programs: [[String: Any]]) {
    guard let sharedDefaults = UserDefaults(suiteName: "group.org.baytides.baynavigator") else {
      print("Failed to access App Group UserDefaults")
      return
    }

    // Convert to SharedProgram format
    var sharedPrograms: [[String: String]] = []
    for program in programs {
      if let id = program["id"] as? String,
         let name = program["name"] as? String,
         let category = program["category"] as? String,
         let description = program["description"] as? String,
         let website = program["website"] as? String {
        sharedPrograms.append([
          "id": id,
          "name": name,
          "category": category,
          "description": description,
          "website": website
        ])
      }
    }

    // Save to App Group
    if let data = try? JSONEncoder().encode(sharedPrograms) {
      sharedDefaults.set(data, forKey: "savedPrograms")
      sharedDefaults.synchronize()
      print("Synced \(sharedPrograms.count) programs to App Group")
    }
  }
}
