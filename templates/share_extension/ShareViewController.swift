import UIKit
import UniformTypeIdentifiers

/// Share-extension intake, generic skeleton (extracted from Ladle).
///
/// Queues the shared URL/text into the app group and pings the host app.
/// Keep this UI minimal: a confirmation card + Done / "Open app". Anything
/// richer (inline processing, previews) is per-app custom work.
///
/// Setup: the app and this extension share an App Group; set [appGroup]
/// and the Darwin notification name below to your slug.
class ShareViewController: UIViewController {
    // TODO(per-app): your App Group + notification name.
    private let appGroup = "group.com.surgestudios.myapp"
    private let queueKey = "pendingImports"
    private let presentKey = "presentImportOnOpen"
    private let enqueuedNotification = "com.surgestudios.myapp.share.enqueued"

    /// The value this invocation queued, so Done/cancel paths can unqueue.
    private var queuedValue: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        handleShare()
    }

    // MARK: Extraction

    private func handleShare() {
        guard
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let providers = item.attachments
        else {
            finish()
            return
        }
        // URL attachment first (Safari), then plain text (TikTok/Instagram
        // share the link inside caption text, not as a URL attachment).
        for provider in providers
        where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] data, _ in
                let url = (data as? URL)?.absoluteString ?? (data as? String)
                DispatchQueue.main.async { self?.onPayload(url) }
            }
            return
        }
        for provider in providers
        where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] data, _ in
                let text = data as? String
                DispatchQueue.main.async { self?.onPayload(text) }
            }
            return
        }
        finish()
    }

    private func onPayload(_ raw: String?) {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty
        else {
            finish()
            return
        }
        // Prefer the URL inside a caption blob; queue the raw text when
        // there is none (the app decides what text means).
        enqueue(Self.sharedURL(in: raw) ?? raw)
        // TODO(per-app): render your queued-confirmation card here, with a
        // Done button calling finish() and an "Open app" button calling
        // openHostApp(). This skeleton just completes immediately.
        finish()
    }

    /// The shared http(s) URL inside a blob of text, via NSDataDetector so
    /// it survives surrounding caption text and trailing punctuation.
    ///
    /// A share blob is usually "caption ... <link>", and captions often
    /// mention a bare domain ("full recipe on myblog.com") that
    /// NSDataDetector also reports as an http link — taking the FIRST match
    /// then imported the wrong URL in production. Prefer links written with
    /// an explicit http(s) scheme, and among those take the LAST (the
    /// shared link trails the caption); fall back to the last detected link.
    static func sharedURL(in text: String) -> String? {
        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        guard let matches = detector?.matches(in: text, options: [], range: range),
              !matches.isEmpty
        else { return nil }
        func httpURL(_ m: NSTextCheckingResult) -> String? {
            guard let url = m.url, let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https"
            else { return nil }
            return url.absoluteString
        }
        let explicit = matches.filter { m in
            guard let r = Range(m.range, in: text) else { return false }
            return text[r].lowercased().hasPrefix("http")
        }
        if let last = explicit.last, let s = httpURL(last) { return s }
        if let last = matches.last, let s = httpURL(last) { return s }
        return nil
    }

    // MARK: Queue (app group)

    private func enqueue(_ value: String) {
        let defaults = UserDefaults(suiteName: appGroup)
        var queue = defaults?.stringArray(forKey: queueKey) ?? []
        queue.append(value)
        defaults?.set(queue, forKey: queueKey)
        queuedValue = value
        postEnqueued()
    }

    /// Remove this invocation's value (user cancelled before handing off).
    private func unqueue() {
        guard let value = queuedValue else { return }
        let defaults = UserDefaults(suiteName: appGroup)
        var queue = defaults?.stringArray(forKey: queueKey) ?? []
        if let idx = queue.lastIndex(of: value) { queue.remove(at: idx) }
        defaults?.set(queue, forKey: queueKey)
        queuedValue = nil
    }

    /// Cross-process ping so a running app drains right away even when it
    /// gets no lifecycle transition (iPad split view, where the app stays
    /// foreground beside Safari). The app observes this via
    /// CFNotificationCenter in its AppDelegate.
    private func postEnqueued() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(enqueuedNotification as CFString),
            nil, nil, true
        )
    }

    // MARK: Handoff

    /// "Open app": flag the share for present-on-open (the app surfaces the
    /// job's progress UI instead of draining silently), then open the host
    /// app. If the open is refused the share still imports on next launch —
    /// the queue is durable, so this is best-effort by design.
    private func openHostApp() {
        UserDefaults(suiteName: appGroup)?.set(true, forKey: presentKey)
        // TODO(per-app): your URL scheme from the manifest (deep_link block).
        guard let url = URL(string: "myapp://import") else { return finish() }
        var responder: UIResponder? = self
        while let r = responder {
            if let application = r as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                break
            }
            responder = r.next
        }
        finish()
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
