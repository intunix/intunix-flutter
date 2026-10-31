# Intunix for Flutter

Show [Intunix](https://intunix.com) feedback forms in Flutter apps. This plugin wraps the native
Intunix SDKs ([Android](https://github.com/intunix/intunix-android),
[iOS](https://github.com/intunix/intunix-ios)), so forms look and behave exactly as on the web and
in native apps: the same questions, pages, conditional questions, icon styles, cadence,
targeting and review requests.

Android 7.0+ (API 24) · iOS 15+

## Install

```yaml
dependencies:
  intunix_flutter:
    git: https://github.com/intunix/intunix-flutter
```

**iOS** uses Swift Package Manager (the iOS SDK is published there):

```bash
flutter config --enable-swift-package-manager
```

**Android** pulls the SDK from JitPack; the plugin adds that repository for you. If your app's
`settings.gradle(.kts)` sets `repositoriesMode` to `FAIL_ON_PROJECT_REPOS`, add
`maven("https://jitpack.io")` to its repositories.

## Use

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Intunix.initialize('ck_your_client_key', options: const IntunixOptions(registerAll: true));
  runApp(const MyApp());
}

Intunix.identify('user-42', traits: {'plan': 'pro'});   // on every login
Intunix.reset();                                         // on logout
Intunix.track('checkout_completed', properties: {'total': 49.0});
Intunix.screen('Checkout');                              // drives "App screen" triggers
Intunix.setContext({'store': 'dhaka-1'});                // sent with responses; null clears
Intunix.showForm('nps-q4');                              // id or slug; respects cadence
```

Modal forms show as a centered dialog, popup and banner forms as a bottom sheet. For an inline
form, put the widget in your layout; it sizes itself to the form:

```dart
IntunixForm(form: 'post-order', onFinished: () => setState(() => done = true))
```

Options, triggers and what is sent are the same as the native SDKs — see their READMEs.
