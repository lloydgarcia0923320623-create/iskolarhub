import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/app_state.dart';
import 'screens/models/scholarship.dart';

class ScholarshipDetailsScreen extends StatelessWidget {
  final AppState state;
  final Scholarship scholarship;
  const ScholarshipDetailsScreen(
      {super.key, required this.state, required this.scholarship});

  Future<void> _apply(BuildContext context) async {
    final uri = Uri.parse(scholarship.applicationUrl);
    if (!uri.hasScheme || uri.host.isEmpty) {
      _showLaunchError(context);
      return;
    }

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      if (!launched) _showLaunchError(context);
    } catch (_) {
      if (!context.mounted) return;
      _showLaunchError(context);
    }
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the provider website.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = state.qualifies(scholarship);
    return Scaffold(
      appBar: AppBar(title: const Text('Scholarship Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.school, size: 30)),
            const SizedBox(width: 14),
            Expanded(
                child: Text(scholarship.name,
                    style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF)))),
          ]),
          const SizedBox(height: 8),
          Text(scholarship.provider,
              style: const TextStyle(color: Color(0xFFCBD5E1))),
          const SizedBox(height: 18),
          Card(
              elevation: 0,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(match ? Icons.check_circle : Icons.info_outline,
                        color: match ? const Color(0xFF10B981) : const Color(0xFFFF9500)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(match
                            ? 'You appear to qualify based on your saved profile.'
                            : 'You do not currently meet all saved matching criteria.',
                            style: const TextStyle(color: Color(0xFFE2E8F0)))),
                  ]))),
          const SizedBox(height: 18),
          const Text('About',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF))),
          const SizedBox(height: 7),
          Text(scholarship.description,
              style: const TextStyle(color: Color(0xFFE2E8F0))),
          const SizedBox(height: 18),
          _Info(
              icon: Icons.grade_outlined,
              title: 'Minimum GWA',
              value: '≤ ${scholarship.minGwa.toStringAsFixed(2)}'),
          _Info(
              icon: Icons.payments_outlined,
              title: 'Household Income',
              value:
                  'Up to ₱${scholarship.maxIncome.toStringAsFixed(0)} / month'),
          _Info(
              icon: Icons.calendar_today_outlined,
              title: 'Deadline',
              value: DateFormat('MMMM d, yyyy').format(scholarship.deadline)),
          if (scholarship.applicationPeriod.isNotEmpty)
            _Info(
                icon: Icons.date_range_outlined,
                title: 'Application Period',
                value: scholarship.applicationPeriod),
          if (scholarship.benefits.isNotEmpty)
            _Info(
                icon: Icons.card_giftcard_outlined,
                title: 'Benefits',
                value: scholarship.benefits),
          const SizedBox(height: 18),
          const Text('Requirements',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF))),
          const SizedBox(height: 7),
          ...scholarship.requirements.map((r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(r,
                    style: const TextStyle(color: Color(0xFFE2E8F0))),
              )),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Record: ${scholarship.verificationStatus.label}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (scholarship.lastVerifiedAt != null)
                    Text(
                        'Last reviewed ${DateFormat('MMMM d, yyyy').format(scholarship.lastVerifiedAt!)}'),
                  if (scholarship.sourceUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _openSource(context),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('View recorded source'),
                    ),
                  const Text(
                    'Source and verification details are record metadata and may become outdated.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (state.loggedIn && !state.adminMode) ...[
            OutlinedButton.icon(
              onPressed: () => _reportInformation(context),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Report outdated or incorrect information'),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: () => state.toggleSaved(scholarship.id),
            icon: Icon(state.saved.contains(scholarship.id)
                ? Icons.bookmark
                : Icons.bookmark_border),
            label: Text(state.saved.contains(scholarship.id)
                ? 'Saved'
                : 'Save Scholarship'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _apply(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Apply on Official Provider Site'),
          ),
        ],
      ),
    );
  }

  Future<void> _reportInformation(BuildContext context) async {
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report scholarship information'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Describe what looks outdated or inconsistent for ${scholarship.name}.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  if (length < 10) return 'Enter at least 10 characters.';
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'What should be reviewed?',
                  hintText:
                      'Include the field and what the official source says.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, noteController.text.trim());
            },
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (!context.mounted || note == null) return;

    try {
      final synced = await state.submitScholarshipReport(
        scholarship: scholarship,
        note: note,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(synced
              ? 'Report sent to the scholarship administrators.'
              : 'Report saved on this device and will sync when you are online.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this report. Please try again.'),
        ),
      );
    }
  }

  Future<void> _openSource(BuildContext context) async {
    final uri = Uri.tryParse(scholarship.sourceUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      _showLaunchError(context);
      return;
    }
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      if (!launched) _showLaunchError(context);
    } catch (_) {
      if (!context.mounted) return;
      _showLaunchError(context);
    }
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String title, value;
  const _Info({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title,
            style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
        subtitle: Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      );
}
