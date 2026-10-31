import 'package:flutter/material.dart';
import 'package:intunix_flutter/intunix_flutter.dart';

// Replace with your client key and a form slug from the Intunix console.
const apiKey = 'ck_your_client_key';
const formSlug = 'your-form-slug';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Intunix.initialize(apiKey, options: const IntunixOptions(registerAll: true, debug: true));
  runApp(const SampleApp());
}

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Intunix sample',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF2F9461)),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _showInline = true;

  @override
  void initState() {
    super.initState();
    Intunix.screen('Home');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Intunix ${Intunix.version}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton(onPressed: () => Intunix.showForm(formSlug), child: const Text('Show form as a popup')),
            FilledButton(onPressed: () => Intunix.track('checkout_completed'), child: const Text('Track "checkout_completed"')),
            FilledButton(onPressed: () => Intunix.identify('demo-user', traits: {'plan': 'pro'}), child: const Text('Identify demo user')),
            FilledButton(onPressed: Intunix.reset, child: const Text('Reset (log out)')),
            const SizedBox(height: 16),
            const Text('Inline form'),
            if (_showInline)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: IntunixForm(form: formSlug, onFinished: () => setState(() => _showInline = false)),
                ),
              ),
          ],
        ),
      );
}
