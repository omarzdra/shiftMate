import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/validation.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  bool register = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ShiftMate Business',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        register
                            ? 'Ustvari račun za bolj usklajen delovni dan.'
                            : 'Tvoje izmene. Tvoja ekipa. Vse na enem mestu.',
                      ),
                      const SizedBox(height: 32),
                      Text(
                        register ? 'Registracija' : 'Dobrodošli nazaj',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: email,
                        decoration: const InputDecoration(labelText: 'E-pošta'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        validator: Validation.email,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: password,
                        decoration: const InputDecoration(labelText: 'Geslo'),
                        obscureText: true,
                        autofillHints: [
                          register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        validator: Validation.password,
                        onFieldSubmitted: (_) => submit(state),
                      ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: state.busy ? null : () => submit(state),
                        child: Text(
                          state.busy
                              ? 'Počakaj …'
                              : register
                              ? 'Ustvari račun'
                              : 'Prijava',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: state.busy
                            ? null
                            : () => setState(() => register = !register),
                        child: Text(
                          register
                              ? 'Že imaš račun? Prijava'
                              : 'Nov uporabnik? Registracija',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> submit(AppState state) async {
    if (!form.currentState!.validate()) return;
    final success = await state.authenticate(
      email.text.trim(),
      password.text,
      register,
    );
    if (success && register && mounted && state.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preveri e-pošto, potrdi naslov in se prijavi.'),
        ),
      );
    }
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), value = TextEditingController();
  bool join = false;
  @override
  void dispose() {
    name.dispose();
    value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dobrodošli'),
        actions: [
          TextButton(
            onPressed: s.busy ? null : s.signOut,
            child: const Text('Odjava'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Poveži se z ekipo',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ustvari svoje podjetje ali sprejmi vabilo delodajalca.',
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Podjetje')),
                      ButtonSegment(value: true, label: Text('Vabilo')),
                    ],
                    selected: {join},
                    onSelectionChanged: s.busy
                        ? null
                        : (v) => setState(() {
                            join = v.first;
                            value.clear();
                          }),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Ime in priimek',
                    ),
                    validator: Validation.required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: value,
                    decoration: InputDecoration(
                      labelText: join ? 'Koda vabila' : 'Ime podjetja',
                    ),
                    validator: Validation.required,
                  ),
                  if (s.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        s.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: s.busy
                        ? null
                        : () async {
                            if (form.currentState!.validate()) {
                              await s.run(
                                () => join
                                    ? s.repository.join(
                                        value.text.trim(),
                                        name.text.trim(),
                                      )
                                    : s.repository.createBusiness(
                                        value.text.trim(),
                                        name.text.trim(),
                                      ),
                              );
                            }
                          },
                    child: Text(join ? 'Pridruži se' : 'Ustvari podjetje'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
