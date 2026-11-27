import 'package:flutter/material.dart';

String dateLabel(DateTime value) {
  final d = value.toLocal();
  return '${d.day.toString().padLeft(2, '0')}. ${d.month.toString().padLeft(2, '0')}. ${d.year}';
}

String timeLabel(DateTime value) {
  final d = value.toLocal();
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String intervalLabel(DateTime a, DateTime b) =>
    '${dateLabel(a)} · ${timeLabel(a)}–${timeLabel(b)}${dateLabel(a) == dateLabel(b) ? '' : ' (${dateLabel(b)})'}';

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.description, {
    super.key,
    this.icon = Icons.event_note_outlined,
  });
  final String title, description;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
    child: Column(
      children: [
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(description, textAlign: TextAlign.center),
      ],
    ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.label, {
    super.key,
    this.good = false,
    this.bad = false,
  });
  final String label;
  final bool good, bad;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: good
          ? const Color(0xFFDCFCE7)
          : bad
          ? const Color(0xFFFEE2E2)
          : const Color(0xFFFEF3C7),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: good
            ? const Color(0xFF166534)
            : bad
            ? const Color(0xFF991B1B)
            : const Color(0xFF92400E),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(
    this.title,
    this.subtitle, {
    super.key,
    this.actions = const [],
  });
  final String title, subtitle;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ],
    ),
  );
}

class DateTimeInput extends StatelessWidget {
  const DateTimeInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    icon: const Icon(Icons.schedule),
    label: Text('$label: ${dateLabel(value)} ${timeLabel(value)}'),
    onPressed: () async {
      final local = value.toLocal();
      final date = await showDatePicker(
        context: context,
        initialDate: local,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (date == null || !context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(local),
      );
      if (time != null) {
        onChanged(
          DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ).toUtc(),
        );
      }
    },
  );
}
