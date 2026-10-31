/// Intunix feedback forms for Flutter apps, backed by the native Intunix Android and iOS SDKs.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Options for [Intunix.initialize]. Names follow the web and native SDKs.
@immutable
class IntunixOptions {
  const IntunixOptions({
    this.apiHost = 'https://api.intunix.com',
    this.register = const [],
    this.registerAll = false,
    this.flushIntervalMs = 5000,
    this.maxQueueSize = 100,
    this.screenTriggerDelayMs = 600,
    this.disableEventApi = false,
    this.debug = false,
  });

  /// API origin. Leave as is unless Intunix gave you another host.
  final String apiHost;

  /// Forms (ids or slugs) whose triggers should be live. Auto-activate forms are live anyway.
  final List<String> register;

  /// Load the whole SDK-enabled catalog instead of only [register].
  final bool registerAll;
  final int flushIntervalMs;
  final int maxQueueSize;

  /// Wait before a screen-triggered form shows.
  final int screenTriggerDelayMs;

  /// Keep tracked events on the device (they still fire event triggers).
  final bool disableEventApi;

  /// Native SDK logs (Logcat / Xcode console).
  final bool debug;

  Map<String, Object?> toMap() => {
        'apiHost': apiHost,
        'register': register,
        'registerAll': registerAll,
        'flushIntervalMs': flushIntervalMs,
        'maxQueueSize': maxQueueSize,
        'screenTriggerDelayMs': screenTriggerDelayMs,
        'disableEventApi': disableEventApi,
        'debug': debug,
      };
}

/// Intunix feedback forms. Call [initialize] once, early in `main()`.
class Intunix {
  Intunix._();

  /// Version of this plugin (the native SDKs it bundles share it).
  static const version = '1.5.6';

  @visibleForTesting
  static const channel = MethodChannel('intunix');

  static Future<void> initialize(String apiKey, {IntunixOptions options = const IntunixOptions()}) =>
      channel.invokeMethod('initialize', {'apiKey': apiKey, 'options': options.toMap()});

  /// Identify the signed-in user. Call on every login.
  static Future<void> identify(String userId, {Map<String, Object?> traits = const {}}) =>
      channel.invokeMethod('identify', {'userId': userId, 'traits': traits});

  /// Call on logout: forgets the user, rotates the anonymous id and ends the session.
  static Future<void> reset() => channel.invokeMethod('reset');

  static Future<void> track(String event, {Map<String, Object?> properties = const {}}) =>
      channel.invokeMethod('track', {'event': event, 'properties': properties});

  /// Tell Intunix which screen is showing. Drives "App screen" triggers and screen targeting.
  static Future<void> screen(String name) => channel.invokeMethod('screen', {'name': name});

  /// Merge values into the session context sent with responses; null clears it.
  static Future<void> setContext(Map<String, Object?>? context) =>
      channel.invokeMethod('setContext', {'context': context});

  static Future<void> clearContext() => setContext(null);

  /// Show a form now (still subject to its cadence and targeting). Accepts the form id or slug.
  static Future<void> showForm(String idOrSlug, {Map<String, Object?>? context}) =>
      channel.invokeMethod('showForm', {'form': idOrSlug, 'context': context});

  /// Make a form's triggers live.
  static Future<void> register(String idOrSlug) => channel.invokeMethod('register', {'form': idOrSlug});

  static Future<void> unregister(String idOrSlug) => channel.invokeMethod('unregister', {'form': idOrSlug});
}

/// A form placed in your own layout (the web SDK's inline form). Takes the form's height,
/// draws nothing until it loads, and collapses once the visitor is done.
class IntunixForm extends StatefulWidget {
  const IntunixForm({super.key, required this.form, this.context, this.onFinished});

  /// Form id or slug.
  final String form;

  /// Values sent with the response, on top of [Intunix.setContext].
  final Map<String, Object?>? context;

  /// Called once the visitor submits or closes the form.
  final VoidCallback? onFinished;

  @override
  State<IntunixForm> createState() => _IntunixFormState();
}

class _IntunixFormState extends State<IntunixForm> {
  static const _viewType = 'intunix/form';
  // A platform view needs a non-zero size before it can measure its content.
  double _height = 1;
  MethodChannel? _events;

  void _onCreated(int id) {
    _events = MethodChannel('intunix/form_$id')
      ..setMethodCallHandler((call) async {
        if (!mounted) return;
        switch (call.method) {
          case 'height':
            final h = (call.arguments as num).toDouble();
            setState(() => _height = h);
          case 'finished':
            widget.onFinished?.call();
        }
      });
  }

  @override
  void dispose() {
    _events?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = {'form': widget.form, 'context': widget.context};
    final Widget view;
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Hybrid composition: text input and accessibility behave like a native view.
      view = PlatformViewLink(
        viewType: _viewType,
        surfaceFactory: (context, controller) => AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        ),
        onCreatePlatformView: (p) {
          final c = PlatformViewsService.initExpensiveAndroidView(
            id: p.id,
            viewType: _viewType,
            layoutDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
            creationParams: params,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () => p.onFocusChanged(true),
          );
          c.addOnPlatformViewCreatedListener(p.onPlatformViewCreated);
          c.addOnPlatformViewCreatedListener(_onCreated);
          return c..create();
        },
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      view = UiKitView(
        viewType: _viewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onCreated,
      );
    } else {
      return const SizedBox.shrink();
    }
    return SizedBox(height: _height, child: view);
  }
}
