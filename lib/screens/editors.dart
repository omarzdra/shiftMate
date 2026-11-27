import 'package:flutter/material.dart';

import '../models/domain.dart';
import '../providers/app_state.dart';
import '../services/validation.dart';
import '../widgets/common.dart';

class EditorField {
  const EditorField(
    this.key,
    this.label, {
    this.value = '',
    this.numeric = false,
    this.optional = false,
  });
  final String key, label, value;
  final bool numeric, optional;
}

Future<Map<String, String>?> editFields(
  BuildContext context,
  String title,
  List<EditorField> fields,
) async {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (_) => _FieldsDialog(title: title, fields: fields),
  );
}

class _FieldsDialog extends StatefulWidget {
  const _FieldsDialog({required this.title, required this.fields});
  final String title;
  final List<EditorField> fields;
  @override
  State<_FieldsDialog> createState() => _FieldsDialogState();
}

class _FieldsDialogState extends State<_FieldsDialog> {
  final form = GlobalKey<FormState>();
  late final controllers = {
    for (final f in widget.fields) f.key: TextEditingController(text: f.value),
  };
  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in widget.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: controllers[f.key],
                  decoration: InputDecoration(labelText: f.label),
                  keyboardType: f.numeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  validator: (v) {
                    if (!f.optional && Validation.required(v) != null) {
                      return 'Obvezno polje.';
                    }
                    if (f.numeric &&
                        (double.tryParse((v ?? '').replaceAll(',', '.')) ==
                                null ||
                            !double.parse(v!.replaceAll(',', '.')).isFinite ||
                            double.parse(v.replaceAll(',', '.')) < 0)) {
                      return 'Vnesi veljavno pozitivno število.';
                    }
                    if (f.key == 'email') return Validation.email(v);
                    return null;
                  },
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Prekliči'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, {
              for (final f in widget.fields)
                f.key: controllers[f.key]!.text.trim(),
            });
          }
        },
        child: const Text('Nadaljuj'),
      ),
    ],
  );
}

class IntervalEditor extends StatefulWidget {
  const IntervalEditor({
    super.key,
    required this.state,
    this.shift,
    this.availability,
    this.logShift,
  });
  final AppState state;
  final Shift? shift, logShift;
  final Availability? availability;
  @override
  State<IntervalEditor> createState() => _IntervalEditorState();
}

class _IntervalEditorState extends State<IntervalEditor> {
  final form = GlobalKey<FormState>();
  late DateTime start, end;
  late final TextEditingController position, breakMinutes, note;
  String? memberId;
  bool available = true, saving = false;
  String? error;
  bool get isLog => widget.logShift != null;
  bool get isAvailability =>
      widget.availability != null || !widget.state.isEmployer && !isLog;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    start =
        widget.shift?.start ??
        widget.availability?.start ??
        widget.logShift?.start ??
        DateTime(now.year, now.month, now.day + 1, 8).toUtc();
    end =
        widget.shift?.end ??
        widget.availability?.end ??
        widget.logShift?.end ??
        start.add(const Duration(hours: 8));
    memberId = widget.shift?.memberId;
    available = widget.availability?.available ?? true;
    position = TextEditingController(text: widget.shift?.position ?? 'Strežba');
    breakMinutes = TextEditingController(text: '30');
    note = TextEditingController();
  }

  @override
  void dispose() {
    position.dispose();
    breakMinutes.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return AlertDialog(
      title: Text(
        isLog
            ? 'Oddaj evidenco'
            : isAvailability
            ? 'Razpoložljivost'
            : widget.shift == null
            ? 'Nova izmena'
            : 'Uredi izmeno',
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DateTimeInput(
                  label: 'Začetek',
                  value: start,
                  onChanged: (v) => setState(() => start = v),
                ),
                const SizedBox(height: 12),
                DateTimeInput(
                  label: 'Konec',
                  value: end,
                  onChanged: (v) => setState(() => end = v),
                ),
                const SizedBox(height: 16),
                const Text('Za nočno izmeno izberi naslednji datum konca.'),
                const SizedBox(height: 16),
                if (isAvailability)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Na voljo'),
                    subtitle: const Text('Izklopi za nerazpoložljivost.'),
                    value: available,
                    onChanged: (v) => setState(() => available = v),
                  ),
                if (!isLog && !isAvailability) ...[
                  TextFormField(
                    controller: position,
                    decoration: const InputDecoration(
                      labelText: 'Delovna pozicija',
                    ),
                    validator: Validation.required,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: memberId ?? '',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Zaposleni'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Nedodeljeno'),
                      ),
                      for (final m in s.data!.members.where(
                        (m) => !m.isEmployer,
                      ))
                        DropdownMenuItem(value: m.id, child: Text(m.name)),
                    ],
                    onChanged: (v) =>
                        setState(() => memberId = v == '' ? null : v),
                  ),
                ],
                if (isLog) ...[
                  TextFormField(
                    controller: breakMinutes,
                    decoration: const InputDecoration(
                      labelText: 'Odmor (minute)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null
                        ? 'Vnesi celo število.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: 'Opomba (neobvezno)',
                    ),
                    maxLength: 2000,
                  ),
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Prekliči'),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(
            saving
                ? 'Shranjujem …'
                : isLog
                ? 'Oddaj v potrditev'
                : 'Shrani',
          ),
        ),
      ],
    );
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (!Validation.interval(start, end)) {
      setState(
        () => error = 'Konec mora biti po začetku, trajanje največ 24 ur.',
      );
      return;
    }
    if (isLog) {
      try {
        Validation.workHours(start, end, int.parse(breakMinutes.text));
      } catch (e) {
        setState(
          () => error = 'Odmor mora biti nenegativen in krajši od dela.',
        );
        return;
      }
    }
    final s = widget.state;
    setState(() {
      saving = true;
      error = null;
    });
    final Json row;
    final String table;
    if (isLog) {
      table = 'work_logs';
      row = {
        'business_id': s.data!.businessId,
        'member_id': s.me!.id,
        'shift_id': widget.logShift!.id,
        'starts_at': start.toUtc().toIso8601String(),
        'ends_at': end.toUtc().toIso8601String(),
        'break_minutes': int.parse(breakMinutes.text),
        'note': note.text.trim(),
      };
    } else if (isAvailability) {
      table = 'availabilities';
      row = Availability(
        id: widget.availability?.id ?? '',
        businessId: s.data!.businessId,
        memberId: s.me!.id,
        start: start,
        end: end,
        available: available,
      ).toJson();
    } else {
      table = 'shifts';
      row = Shift(
        id: widget.shift?.id ?? '',
        businessId: s.data!.businessId,
        start: start,
        end: end,
        position: position.text.trim(),
        memberId: memberId,
      ).toJson();
    }
    final ok = await s.run(() => s.repository.save(table, row));
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        error = s.error ?? 'Shranjevanje ni uspelo.';
      });
    }
  }
}

Future<void> deleteEntry(
  BuildContext context,
  AppState state,
  String table,
  String id,
) async {
  final approved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Izbriši vnos?'),
      content: const Text(
        'Izbris bo trajno shranjen. Izmene z oddano evidenco ni mogoče izbrisati.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Prekliči'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Izbriši'),
        ),
      ],
    ),
  );
  if (approved == true) {
    await state.run(() => state.repository.delete(table, id));
  }
}
