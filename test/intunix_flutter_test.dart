import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intunix_flutter/intunix_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(Intunix.channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  test('initialize sends the key and every option', () async {
    await Intunix.initialize('ck_1', options: const IntunixOptions(registerAll: true, register: ['nps']));
    expect(calls.single.method, 'initialize');
    final args = calls.single.arguments as Map;
    expect(args['apiKey'], 'ck_1');
    expect(args['options'], {
      'apiHost': 'https://api.intunix.com',
      'register': ['nps'],
      'registerAll': true,
      'flushIntervalMs': 5000,
      'maxQueueSize': 100,
      'screenTriggerDelayMs': 600,
      'disableEventApi': false,
      'debug': false,
    });
  });

  test('each call maps to its native method and arguments', () async {
    await Intunix.identify('u1', traits: {'plan': 'pro'});
    await Intunix.track('checkout', properties: {'total': 49.5});
    await Intunix.screen('Home');
    await Intunix.setContext({'store': 'dhaka'});
    await Intunix.clearContext();
    await Intunix.showForm('nps', context: {'order': 7});
    await Intunix.register('nps');
    await Intunix.unregister('nps');
    await Intunix.reset();
    expect(calls.map((c) => c.method).toList(), [
      'identify', 'track', 'screen', 'setContext', 'setContext', 'showForm', 'register', 'unregister', 'reset',
    ]);
    expect(calls[0].arguments, {'userId': 'u1', 'traits': {'plan': 'pro'}});
    expect(calls[1].arguments, {'event': 'checkout', 'properties': {'total': 49.5}});
    expect(calls[4].arguments, {'context': null});
    expect(calls[5].arguments, {'form': 'nps', 'context': {'order': 7}});
  });
}
