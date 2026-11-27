import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/domain.dart';
import '../providers/app_state.dart';
import '../services/dashboard_summary.dart';
import '../widgets/common.dart';
import 'editors.dart';
import 'scheduling_screen.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final labels = [
      'Pregled',
      s.isEmployer ? 'Urnik' : 'Moje izmene',
      s.isEmployer ? 'Zaposleni' : 'Na voljo',
      'Delovne ure',
      'Profil',
    ];
    const icons = [
      Icons.space_dashboard_outlined,
      Icons.calendar_month_outlined,
      Icons.people_outline,
      Icons.timer_outlined,
      Icons.person_outline,
    ];
    final content = Column(
      children: [
        if (s.busy) const LinearProgressIndicator(minHeight: 2),
        if (s.offline)
          const MaterialBanner(
            content: Text(
              'Brez povezave · prikaz zadnjih shranjenih podatkov. Spremembe niso na voljo.',
            ),
            leading: Icon(Icons.cloud_off_outlined),
            actions: [SizedBox.shrink()],
          ),
        if (s.error != null)
          MaterialBanner(
            content: Text(s.error!),
            actions: [
              TextButton(
                onPressed: s.busy ? null : s.refresh,
                child: const Text('Poskusi znova'),
              ),
            ],
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: s.refresh,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: switch (index) {
                  0 => DashboardPage(
                    onNavigate: (v) => setState(() => index = v),
                  ),
                  1 => const ShiftsPage(),
                  2 =>
                    s.isEmployer
                        ? const EmployeesPage()
                        : const AvailabilityPage(),
                  3 => const WorkHoursPage(),
                  _ => const ProfilePage(),
                },
              ),
            ),
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ShiftMate',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  s.data!.businessName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Osveži podatke',
                onPressed: s.busy ? null : s.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: index,
                      onDestinationSelected: (v) => setState(() => index = v),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (var i = 0; i < labels.length; i++)
                          NavigationRailDestination(
                            icon: Icon(icons[i]),
                            label: Text(labels[i]),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (v) => setState(() => index = v),
                  destinations: [
                    for (var i = 0; i < labels.length; i++)
                      NavigationDestination(
                        icon: Icon(icons[i]),
                        label: labels[i],
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTimeRange? range;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final from = range?.start ?? DateTime(now.year, now.month);
    final until = range == null
        ? DateTime(now.year, now.month + 1)
        : DateTime(range!.end.year, range!.end.month, range!.end.day + 1);
    final summary = DashboardSummary(s.data!, s.me!, now, from, until);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          'Dober dan, ${s.me!.name.split(' ').first}.',
          s.isEmployer
              ? 'Pregled ekipe in naslednjih izmen.'
              : 'Tvoj delovni dan na enem mestu.',
          actions: [
            if (s.isEmployer) ...[
              FilledButton.icon(
                onPressed: s.busy || s.offline
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) => IntervalEditor(state: s),
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Nova izmena'),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.onNavigate(2),
                icon: const Icon(Icons.people_outline),
                label: const Text('Zaposleni'),
              ),
              OutlinedButton.icon(
                onPressed: s.busy || s.offline
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SchedulingScreen(state: s),
                        ),
                      ),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Samodejni urnik'),
              ),
            ] else ...[
              FilledButton(
                onPressed: () => widget.onNavigate(2),
                child: const Text('Moja razpoložljivost'),
              ),
              OutlinedButton(
                onPressed: () => widget.onNavigate(3),
                child: const Text('Oddaj delovne ure'),
              ),
            ],
          ],
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final selected = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              initialDateRange:
                  range ??
                  DateTimeRange(
                    start: from,
                    end: until.subtract(const Duration(days: 1)),
                  ),
            );
            if (selected != null && mounted) setState(() => range = selected);
          },
          icon: const Icon(Icons.date_range),
          label: Text(
            '${dateLabel(from)} – ${dateLabel(until.subtract(const Duration(days: 1)))}',
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth >= 600
                ? (c.maxWidth - 24) / 3
                : (c.maxWidth - 12) / 2;
            final values = s.isEmployer
                ? [
                    ('Zaposleni', '${summary.employees}'),
                    ('Današnje izmene', '${summary.today}'),
                    ('Nedodeljene izmene', '${summary.unassigned}'),
                    ('Čaka na potrditev', '${summary.pending}'),
                    (
                      'Potrjene ure',
                      '${summary.approvedHours.toStringAsFixed(1)} h',
                    ),
                  ]
                : [
                    (
                      'Opravljene ure',
                      '${summary.totalHours.toStringAsFixed(1)} h',
                    ),
                    (
                      'Ure v čakanju',
                      '${summary.pendingHours.toStringAsFixed(1)} h',
                    ),
                    (
                      'Potrjene ure',
                      '${summary.approvedHours.toStringAsFixed(1)} h',
                    ),
                    (
                      'Predvideno plačilo',
                      '${summary.pay.toStringAsFixed(2)} €',
                    ),
                  ];
            return Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final v in values)
                  SizedBox(
                    width: width,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.$1),
                            const SizedBox(height: 12),
                            Text(
                              v.$2,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (!s.isEmployer)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text(
              'Informativni izračun iz potrjenih ur. To ni uradni obračun plače.',
            ),
          ),
        const SizedBox(height: 12),
        Text(
          s.isEmployer ? 'Prihajajoče izmene' : 'Naslednje izmene',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (summary.upcoming.isEmpty)
          const EmptyState(
            'Ni prihajajočih izmen',
            'Nove dodelitve se bodo pojavile tukaj.',
          ),
        for (final shift in summary.upcoming.take(5))
          ShiftCard(shift: shift, state: s),
      ],
    );
  }
}

class ShiftCard extends StatelessWidget {
  const ShiftCard({
    super.key,
    required this.shift,
    required this.state,
    this.onEdit,
    this.onDelete,
  });
  final Shift shift;
  final AppState state;
  final VoidCallback? onEdit, onDelete;
  @override
  Widget build(BuildContext context) {
    final member = state.data!.members
        .where((m) => m.id == shift.memberId)
        .firstOrNull;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(state.compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    intervalLabel(shift.start, shift.end),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onEdit != null)
                  PopupMenuButton<String>(
                    tooltip: 'Možnosti izmene',
                    onSelected: (v) => v == 'edit' ? onEdit!() : onDelete!(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Uredi')),
                      PopupMenuItem(value: 'delete', child: Text('Izbriši')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${shift.position} · ${shift.hours.toStringAsFixed(1)} h'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(
                  shift.memberId == null ? 'Nedodeljeno' : 'Dodeljeno',
                  good: shift.memberId != null,
                ),
                if (member != null) Text(member.name),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShiftsPage extends StatelessWidget {
  const ShiftsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          s.isEmployer ? 'Urnik' : 'Moje izmene',
          'Razpored po datumu. Časi so prikazani v lokalnem času naprave.',
          actions: [
            if (s.isEmployer) ...[
              FilledButton.icon(
                onPressed: s.busy || s.offline
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) => IntervalEditor(state: s),
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Nova izmena'),
              ),
              OutlinedButton.icon(
                onPressed: s.busy || s.offline
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SchedulingScreen(state: s),
                        ),
                      ),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Samodejni urnik'),
              ),
            ],
          ],
        ),
        if (s.data!.shifts.isEmpty)
          const EmptyState(
            'Ni izmen',
            'Delodajalec lahko ustvari prvo izmeno.',
          ),
        for (final shift in s.data!.shifts)
          ShiftCard(
            shift: shift,
            state: s,
            onEdit: s.isEmployer && !s.offline && !s.busy
                ? () => showDialog<void>(
                    context: context,
                    builder: (_) => IntervalEditor(state: s, shift: shift),
                  )
                : null,
            onDelete: () => deleteEntry(context, s, 'shifts', shift.id),
          ),
      ],
    );
  }
}

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final members = s.data!.members.where((m) => !m.isEmployer).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          'Zaposleni',
          'Ekipa, delovne pozicije in urne postavke.',
          actions: [
            FilledButton.icon(
              onPressed: s.busy || s.offline ? null : () => invite(context, s),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Povabi zaposlenega'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Razpoložljivost ekipe')),
                    body: const AvailabilityPage(),
                  ),
                ),
              ),
              icon: const Icon(Icons.event_available),
              label: const Text('Razpoložljivost ekipe'),
            ),
          ],
        ),
        if (members.isEmpty)
          const EmptyState(
            'Ekipa še ni povezana',
            'Povabi zaposlenega z njegovim e-poštnim naslovom.',
          ),
        for (final m in members)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                child: Text(m.name.substring(0, 1).toUpperCase()),
              ),
              title: Text(m.name),
              subtitle: Text(
                '${m.position}\n${m.hourlyRate.toStringAsFixed(2)} €/h · največ ${m.maxWeeklyHours.toStringAsFixed(0)} h/teden',
              ),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Uredi zaposlenega',
                onPressed: s.offline || s.busy
                    ? null
                    : () => editMember(context, s, m),
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> invite(BuildContext context, AppState s) async {
    final values = await editFields(context, 'Povabi zaposlenega', const [
      EditorField('email', 'E-pošta'),
      EditorField('position', 'Delovna pozicija', value: 'Strežba'),
      EditorField('rate', 'Urna postavka (€)', value: '10', numeric: true),
      EditorField('hours', 'Največ ur na teden', value: '40', numeric: true),
    ]);
    if (values == null) return;
    String? token;
    final ok = await s.run(() async {
      token = await s.repository.invite(
        values['email']!,
        values['position']!,
        double.parse(values['rate']!.replaceAll(',', '.')),
        double.parse(values['hours']!.replaceAll(',', '.')),
      );
    });
    if (ok && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Vabilo je pripravljeno'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kodo posreduj osebi ${values['email']}. Velja 7 dni in jo lahko uporabi samo ta potrjeni e-poštni naslov.',
              ),
              const SizedBox(height: 16),
              SelectableText(token!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: token!));
              },
              child: const Text('Kopiraj kodo'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zapri'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> editMember(BuildContext context, AppState s, Member m) async {
    final v = await editFields(context, 'Podatki zaposlenega', [
      EditorField('name', 'Ime in priimek', value: m.name),
      EditorField('position', 'Delovna pozicija', value: m.position),
      EditorField(
        'rate',
        'Urna postavka (€)',
        value: '${m.hourlyRate}',
        numeric: true,
      ),
      EditorField(
        'hours',
        'Največ ur na teden',
        value: '${m.maxWeeklyHours}',
        numeric: true,
      ),
    ]);
    if (v != null) {
      await s.run(
        () => s.repository.save('business_members', {
          'id': m.id,
          'name': v['name'],
          'position': v['position'],
          'hourly_rate': double.parse(v['rate']!.replaceAll(',', '.')),
          'max_weekly_hours': double.parse(v['hours']!.replaceAll(',', '.')),
        }),
      );
    }
  }
}

class AvailabilityPage extends StatelessWidget {
  const AvailabilityPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final entries = s.data!.availabilities;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          s.isEmployer ? 'Razpoložljivost ekipe' : 'Moja razpoložljivost',
          'Določi celoten časovni interval. Nerazpoložljivost ima prednost.',
          actions: [
            if (!s.isEmployer)
              FilledButton.icon(
                onPressed: s.busy || s.offline
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) => IntervalEditor(state: s),
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj razpoložljivost'),
              ),
          ],
        ),
        if (entries.isEmpty)
          const EmptyState(
            'Ni razpoložljivosti',
            'Dodaj termine, da bo mogoče načrtovati izmene.',
          ),
        for (final a in entries)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intervalLabel(a.start, a.end),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (s.isEmployer)
                    Text(
                      s.data!.members
                              .where((m) => m.id == a.memberId)
                              .firstOrNull
                              ?.name ??
                          'Zaposleni',
                    ),
                  const SizedBox(height: 8),
                  StatusBadge(
                    a.available ? 'Na voljo' : 'Ni na voljo',
                    good: a.available,
                    bad: !a.available,
                  ),
                  if (!s.isEmployer)
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: s.busy || s.offline
                              ? null
                              : () => showDialog<void>(
                                  context: context,
                                  builder: (_) =>
                                      IntervalEditor(state: s, availability: a),
                                ),
                          child: const Text('Uredi'),
                        ),
                        TextButton(
                          onPressed: s.busy || s.offline
                              ? null
                              : () => deleteEntry(
                                  context,
                                  s,
                                  'availabilities',
                                  a.id,
                                ),
                          child: const Text('Izbriši'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class WorkHoursPage extends StatefulWidget {
  const WorkHoursPage({super.key});
  @override
  State<WorkHoursPage> createState() => _WorkHoursPageState();
}

class _WorkHoursPageState extends State<WorkHoursPage> {
  String status = 'all', member = 'all';
  DateTimeRange? range;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final logs = s.data!.logs
        .where(
          (l) =>
              (status == 'all' || l.status.name == status) &&
              (member == 'all' || l.memberId == member) &&
              (range == null ||
                  !l.start.isBefore(range!.start) &&
                      l.start.isBefore(
                        DateTime(
                          range!.end.year,
                          range!.end.month,
                          range!.end.day + 1,
                        ),
                      )),
        )
        .toList();
    final pay = logs.fold<double>(0, (v, l) => v + l.pay);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          'Delovne ure',
          s.isEmployer
              ? 'Preglej oddane evidence in potrdi opravljeno delo.'
              : 'Oddaj ure za opravljeno izmeno in spremljaj potrditev.',
          actions: [
            if (!s.isEmployer)
              FilledButton.icon(
                onPressed: s.busy || s.offline
                    ? null
                    : () => submit(context, s),
                icon: const Icon(Icons.add),
                label: const Text('Oddaj evidenco'),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pair in [
              ('all', 'Vse'),
              ('pending', 'V čakanju'),
              ('approved', 'Potrjeno'),
              ('rejected', 'Zavrnjeno'),
            ])
              ChoiceChip(
                label: Text(pair.$2),
                selected: status == pair.$1,
                onSelected: (_) => setState(() => status = pair.$1),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (s.isEmployer)
          DropdownButtonFormField<String>(
            initialValue: member,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Zaposleni'),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Vsi zaposleni'),
              ),
              for (final m in s.data!.members.where((m) => !m.isEmployer))
                DropdownMenuItem(value: m.id, child: Text(m.name)),
            ],
            onChanged: (v) => setState(() => member = v!),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final v = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDateRange: range,
                );
                if (v != null && mounted) setState(() => range = v);
              },
              icon: const Icon(Icons.date_range),
              label: Text(
                range == null
                    ? 'Izberi obdobje'
                    : '${dateLabel(range!.start)} – ${dateLabel(range!.end)}',
              ),
            ),
            if (range != null)
              TextButton(
                onPressed: () => setState(() => range = null),
                child: const Text('Vsa obdobja'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Predvideno plačilo · ${pay.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Informativni izračun iz potrjenih ur v prikazanem izboru. To ni uradni obračun plače.',
                ),
              ],
            ),
          ),
        ),
        if (logs.isEmpty)
          const EmptyState(
            'Ni evidenc',
            'Oddane evidence se bodo pojavile tukaj.',
          ),
        for (final l in logs)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.data!.members
                            .where((m) => m.id == l.memberId)
                            .firstOrNull
                            ?.name ??
                        'Moja evidenca',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(intervalLabel(l.start, l.end)),
                  Text(
                    '${l.hours.toStringAsFixed(2)} h · odmor ${l.breakMinutes} min · ${l.hourlyRate.toStringAsFixed(2)} €/h',
                  ),
                  if (l.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(l.note),
                    ),
                  const SizedBox(height: 12),
                  StatusBadge(
                    switch (l.status) {
                      LogStatus.pending => 'V čakanju',
                      LogStatus.approved => 'Potrjeno',
                      LogStatus.rejected => 'Zavrnjeno',
                    },
                    good: l.status == LogStatus.approved,
                    bad: l.status == LogStatus.rejected,
                  ),
                  if (l.rejectionReason.isNotEmpty)
                    Text('Razlog: ${l.rejectionReason}'),
                  if (s.isEmployer && l.status == LogStatus.pending)
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: s.busy || s.offline
                              ? null
                              : () => s.run(
                                  () => s.repository.review(l.id, true, ''),
                                ),
                          icon: const Icon(Icons.check),
                          label: const Text('Potrdi'),
                        ),
                        TextButton(
                          onPressed: s.busy || s.offline
                              ? null
                              : () async {
                                  final v = await editFields(
                                    context,
                                    'Zavrni evidenco',
                                    const [
                                      EditorField('reason', 'Razlog zavrnitve'),
                                    ],
                                  );
                                  if (v != null) {
                                    await s.run(
                                      () => s.repository.review(
                                        l.id,
                                        false,
                                        v['reason']!,
                                      ),
                                    );
                                  }
                                },
                          child: const Text('Zavrni'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> submit(BuildContext context, AppState s) async {
    final shifts = s.data!.shifts
        .where(
          (shift) =>
              shift.memberId == s.me!.id &&
              shift.start.isBefore(DateTime.now()) &&
              !s.data!.logs.any((l) => l.shiftId == shift.id),
        )
        .toList();
    final selected = await showDialog<Shift>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Izberi opravljeno izmeno'),
        children: shifts.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Ni izmen brez oddane evidence.'),
                ),
              ]
            : [
                for (final shift in shifts)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, shift),
                    child: Text(intervalLabel(shift.start, shift.end)),
                  ),
              ],
      ),
    );
    if (selected != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => IntervalEditor(state: s, logShift: selected),
      );
    }
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeading('Profil', 'Račun in nastavitve prikaza.'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.me!.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(s.repository.email ?? ''),
                const SizedBox(height: 16),
                StatusBadge(
                  s.isEmployer ? 'Delodajalec' : 'Delavec',
                  good: true,
                ),
                const SizedBox(height: 16),
                Text(s.data!.businessName),
              ],
            ),
          ),
        ),
        Card(
          child: SwitchListTile(
            title: const Text('Strnjen prikaz izmen'),
            subtitle: const Text('Nastavitev se shrani na tej napravi.'),
            value: s.compact,
            onChanged: s.setCompact,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: s.busy ? null : s.signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Odjava'),
        ),
      ],
    );
  }
}
