import Flutter
import UIKit
import Intunix

/// Bridges the `intunix` channel to the native Intunix iOS SDK.
public class IntunixFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "intunix", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(IntunixFlutterPlugin(), channel: channel)
        registrar.register(FormFactory(messenger: registrar.messenger()), withId: "intunix/form")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let a = call.arguments as? [String: Any] ?? [:]
        func map(_ k: String) -> [String: Any]? { a[k] as? [String: Any] }
        let form = a["form"] as? String ?? ""
        switch call.method {
        case "initialize":
            let o = map("options") ?? [:]
            Intunix.initialize(apiKey: a["apiKey"] as? String ?? "", options: IntunixOptions(
                apiHost: o["apiHost"] as? String ?? "https://api.intunix.com",
                register: o["register"] as? [String] ?? [],
                registerAll: o["registerAll"] as? Bool ?? false,
                flushIntervalMs: UInt64((o["flushIntervalMs"] as? NSNumber)?.intValue ?? 5000),
                maxQueueSize: (o["maxQueueSize"] as? NSNumber)?.intValue ?? 100,
                screenTriggerDelayMs: UInt64((o["screenTriggerDelayMs"] as? NSNumber)?.intValue ?? 600),
                disableEventApi: o["disableEventApi"] as? Bool ?? false,
                debug: o["debug"] as? Bool ?? false,
                theme: (o["theme"] as? String).flatMap(IntunixTheme.init(rawValue:)) ?? .auto))
        case "identify": Intunix.identify(a["userId"] as? String ?? "", traits: map("traits") ?? [:])
        case "reset": Intunix.reset()
        case "track": Intunix.track(a["event"] as? String ?? "", properties: map("properties") ?? [:])
        case "screen": Intunix.screen(a["name"] as? String ?? "")
        case "setContext": Intunix.setContext(map("context"))
        case "showForm": Intunix.showForm(form, context: map("context"))
        case "register": Intunix.register(form)
        case "unregister": Intunix.unregister(form)
        case "setTheme": if let t = (a["theme"] as? String).flatMap(IntunixTheme.init(rawValue:)) { Intunix.setTheme(t) }
        default: return result(FlutterMethodNotImplemented)
        }
        result(nil)
    }
}

private final class FormFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    init(messenger: FlutterBinaryMessenger) { self.messenger = messenger }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        FormPlatformView(id: viewId, args: args as? [String: Any], messenger: messenger)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol { FlutterStandardMessageCodec.sharedInstance() }
}

/// The inline form; reports its height (points) and completion to Dart.
private final class FormPlatformView: NSObject, FlutterPlatformView {
    private let form = IntunixFormUIView()
    private let events: FlutterMethodChannel

    init(id: Int64, args: [String: Any]?, messenger: FlutterBinaryMessenger) {
        events = FlutterMethodChannel(name: "intunix/form_\(id)", binaryMessenger: messenger)
        super.init()
        form.onHeightChanged = { [weak self] h in self?.events.invokeMethod("height", arguments: Double(max(h, 1))) }
        form.onFinished = { [weak self] in self?.events.invokeMethod("finished", arguments: nil) }
        applyTheme(args ?? [:])
        form.setForm(args?["form"] as? String ?? "", context: args?["context"] as? [String: Any])
        // Dart sends the app's brightness and the theme prop again whenever they change.
        events.setMethodCallHandler { [weak self] call, result in
            guard call.method == "theme" else { return result(FlutterMethodNotImplemented) }
            self?.applyTheme(call.arguments as? [String: Any] ?? [:])
            result(nil)
        }
    }

    /// The Flutter app's brightness becomes the view's interface style, which the form reads in auto.
    private func applyTheme(_ a: [String: Any]) {
        form.theme = (a["theme"] as? String).flatMap(IntunixTheme.init(rawValue:))
        switch a["hostDark"] as? Bool {
        case true?: form.overrideUserInterfaceStyle = .dark
        case false?: form.overrideUserInterfaceStyle = .light
        case nil: form.overrideUserInterfaceStyle = .unspecified
        }
    }

    func view() -> UIView { form }
}
