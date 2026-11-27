import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'providers/app_state.dart';
import 'repositories/supabase_repository.dart';
import 'screens/auth_screen.dart';
import 'screens/workspace_screen.dart';
import 'services/local_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  if (url.isEmpty || key.isEmpty) {
    runApp(const ShiftMateApp());
    return;
  }
  try {
    await Supabase.initialize(url: url, publishableKey: key);
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(
      'shiftmate_${Uri.parse(url).host.replaceAll('.', '_')}',
    );
    final state = AppState(
      SupabaseRepository(Supabase.instance.client),
      HiveCache(box),
    );
    runApp(ShiftMateApp(state: state));
    if (state.userId != null) await state.refresh();
  } catch (_) {
    runApp(
      const ShiftMateApp(
        startupError: 'Aplikacije ni mogoče pripraviti. Preveri konfiguracijo in ponovno zaženi aplikacijo.',
      ),
    );
  }
}

class ShiftMateApp extends StatelessWidget {
  const ShiftMateApp({super.key, this.state, this.startupError});
  final AppState? state;
  final String? startupError;
  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'ShiftMate Business',
      debugShowCheckedModeBanner: false,
      theme: shiftMateTheme(),
      locale: const Locale('sl'),
      supportedLocales: const [Locale('sl')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: state == null
          ? ConfigurationScreen(error: startupError)
          : const SessionGate(),
    );
    return state == null
        ? app
        : ChangeNotifierProvider.value(
            value: state!,
            child: ListenableBuilder(
              listenable: state!,
              builder: (context, _) => KeyedSubtree(
                key: ValueKey(
                  '${state!.userId}:${state!.data?.businessId}:${state!.me?.role}',
                ),
                child: app,
              ),
            ),
          );
  }
}

class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key, this.error});
  final String? error;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ShiftMate Business')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.settings_outlined, size: 40),
              const SizedBox(height: 24),
              Text(
                'Priprava povezave',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                error ?? 'Ta gradnja še ni povezana s podjetjem. Za zagon uporabi SUPABASE_URL in SUPABASE_PUBLISHABLE_KEY po navodilih v README.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Za tehnično gradnjo povezava ni potrebna. Prijava in poslovni podatki potrebujejo konfiguriran Supabase projekt.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.userId == null) return const AuthScreen();
    if (s.data != null && s.me != null) return const WorkspaceScreen();
    if (s.busy) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (s.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Povezava s podjetjem')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.error!),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: s.refresh,
                  child: const Text('Poskusi znova'),
                ),
                TextButton(onPressed: s.signOut, child: const Text('Odjava')),
              ],
            ),
          ),
        ),
      );
    }
    return const OnboardingScreen();
  }
}
