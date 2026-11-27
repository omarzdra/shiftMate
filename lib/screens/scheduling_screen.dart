import 'package:flutter/material.dart';

import '../models/domain.dart';
import '../providers/app_state.dart';
import '../services/scheduling_service.dart';
import '../providers/scheduling_state.dart';
import '../widgets/common.dart';

class SchedulingScreen extends StatefulWidget {
  const SchedulingScreen({super.key, required this.state});
  final AppState state;
  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  late DateTimeRange range;
  late final SchedulingState controller;
  ScheduleProposal? get proposal => controller.proposal;
  String? get error => controller.error;
  bool get saving => controller.saving;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    range = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day + 6),
    );
    controller = SchedulingState(widget.state)..addListener(changed);
    widget.state.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.state.removeListener(changed);
    controller.removeListener(changed);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final data = s.data;
    if (data == null || !s.isEmployer) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Seja ni več veljavna. Vrni se na prijavo.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Predlog urnika')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const PageHeading(
                'Uskladi naslednje izmene',
                'Predlog preveri in po potrebi spremeni. Urnik se shrani šele ob potrditvi.',
              ),
              OutlinedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final selected = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDateRange: range,
                        );
                        if (selected != null && mounted) {
                          setState(() {
                            range = selected;
                            controller.clear();
                          });
                        }
                      },
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${dateLabel(range.start)} – ${dateLabel(range.end)}',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving || s.busy || s.offline ? null : generate,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Pripravi predlog'),
              ),
              if (proposal != null) ...[
                const SizedBox(height: 24),
                Text(
                  '${proposal!.shifts.where((s) => s.memberId != null).length} dodeljenih · ${proposal!.shifts.where((s) => s.memberId == null).length} nepokritih',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (proposal!.shifts.isEmpty)
                  const EmptyState(
                    'Ni nedodeljenih izmen',
                    'Izberi drugo obdobje ali ustvari nove izmene.',
                  ),
                for (final shift in proposal!.shifts)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            intervalLabel(shift.start, shift.end),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(shift.position),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey('${shift.id}:${shift.memberId}'),
                            initialValue: shift.memberId ?? '',
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Predlagana dodelitev',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Nedodeljeno'),
                              ),
                              for (final m in data.members.where(
                                (m) => !m.isEmployer,
                              ))
                                DropdownMenuItem(
                                  value: m.id,
                                  child: Text(m.name),
                                ),
                            ],
                            onChanged: saving
                                ? null
                                : (v) => change(shift, v == '' ? null : v),
                          ),
                          if (shift.memberId == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                proposal!.reasons[shift.id] ??
                                    'Ročno puščeno nedodeljeno',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed:
                      saving ||
                          s.busy ||
                          s.offline ||
                          proposal!.shifts.every((s) => s.memberId == null)
                      ? null
                      : confirm,
                  child: Text(
                    saving
                        ? 'Preverjam in shranjujem …'
                        : 'Potrdi in shrani urnik',
                  ),
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
    );
  }

  void generate() => controller.generate(
    range.start,
    DateTime(range.end.year, range.end.month, range.end.day + 1),
  );
  void change(Shift shift, String? memberId) =>
      controller.change(shift, memberId);
  Future<void> confirm() async {
    final ok = await controller.confirm();
    if (ok && mounted) Navigator.pop(context);
  }
}
