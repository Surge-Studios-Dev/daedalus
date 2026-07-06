import Flutter
import UIKit

/// Host-app half of the share-extension intake (extracted from Ladle).
/// Answers the share method channel from app-group storage and forwards
/// the extension's cross-process "queued" ping to Dart as `drainNow`.
///
/// Merge into the stamped app's AppDelegate; set the three constants to
/// match ShareViewController.swift.
@main
@objc class AppDelegate: FlutterAppDelegate {
  // TODO(per-app): must match the extension's constants.
  private let appGroup = "group.com.surgestudios.myapp"
  private let queueKey = "pendingImports"
  private let presentKey = "presentImportOnOpen"
  private let enqueuedNotification = "com.surgestudios.myapp.share.enqueued"

  private var shareChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      // TODO(per-app): channel name "<slug>/share".
      let channel = FlutterMethodChannel(
        name: "myapp/share", binaryMessenger: controller.binaryMessenger)
      shareChannel = channel
      registerShareObserver()
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return result(nil) }
        let defaults = UserDefaults(suiteName: self.appGroup)
        switch call.method {
        case "drainPendingImports":
          // Return AND clear: the Dart side moves values into its durable
          // inbox before starting anything, so a kill can't lose a share.
          let queue = defaults?.stringArray(forKey: self.queueKey) ?? []
          defaults?.removeObject(forKey: self.queueKey)
          result(queue)
        case "takePresentOnOpen":
          // One shot, read-and-clear. Set by the extension's "Open app";
          // tells Dart to surface the fresh share's progress UI rather than
          // draining silently.
          let flag = defaults?.bool(forKey: self.presentKey) ?? false
          defaults?.removeObject(forKey: self.presentKey)
          result(flag)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Observe the extension's cross-process "queued" notification and poke
  /// Dart to drain. Covers the case where no app lifecycle transition fires
  /// (iPad split view) — a resume-only drain misses it.
  private func registerShareObserver() {
    CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      Unmanaged.passUnretained(self).toOpaque(),
      { (_, observer, _, _, _) in
        guard let observer = observer else { return }
        let delegate = Unmanaged<AppDelegate>.fromOpaque(observer)
          .takeUnretainedValue()
        DispatchQueue.main.async { delegate.notifyShareEnqueued() }
      },
      enqueuedNotification as CFString,
      nil,
      .deliverImmediately
    )
  }

  private func notifyShareEnqueued() {
    shareChannel?.invokeMethod("drainNow", arguments: nil)
  }
}
