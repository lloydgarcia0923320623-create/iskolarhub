import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../scholarship_details_screen.dart';
import 'models/application_status.dart';

class ChecklistScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback? onBrowseScholarships;
  const ChecklistScreen(
      {super.key, required this.state, this.onBrowseScholarships});

  @override
  Widget build(BuildContext context) {
    final saved =
        state.scholarships.where((s) => state.saved.contains(s.id)).toList();
    if (saved.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checklist_outlined,
                  size: 58, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Your checklist is waiting.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Save a scholarship to start tracking its document requirements.',
                textAlign: TextAlign.center,
              ),
              if (onBrowseScholarships != null) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onBrowseScholarships,
                  icon: const Icon(Icons.search),
                  label: const Text('Browse scholarships'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Document Checklist',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const Text(
            'Track requirements and your self-reported progress for saved scholarships.'),
        const SizedBox(height: 6),
        const Text(
          'Readiness is a personal organization aid. It does not confirm eligibility, document validity, or approval.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 18),
        ...saved.map((s) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 14),
              child: ExpansionTile(
                title: Text(s.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${s.requirements.where((r) => state.isDocDone(s.id, r)).length}/${s.requirements.length} completed'),
                children: [
                  ListTile(
                    title: const Text('Application status'),
                    subtitle: Text(state.applicationStatusSyncError ??
                        (state.applicationStatusSyncEnabled
                            ? 'Live sync is on for your Google account. Provider systems are not connected.'
                            : 'Saved on this device. Sign in with Google to sync across devices. Provider systems are not connected.')),
                    trailing: DropdownButton<ApplicationStatus>(
                      value: state.applicationStatus(s.id),
                      items: ApplicationStatus.values
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              ))
                          .toList(),
                      onChanged: (status) {
                        if (status != null) {
                          state.updateApplicationStatus(s.id, status).then<void>(
                            (_) {},
                            onError: (Object error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Could not sync application status: $error'),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                  Builder(builder: (context) {
                    final complete = s.requirements
                        .where((doc) => state.isDocDone(s.id, doc))
                        .length;
                    final readiness = s.requirements.isEmpty
                        ? 0.0
                        : complete / s.requirements.length;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                    '$complete of ${s.requirements.length} ready'),
                              ),
                              Text('${(readiness * 100).round()}%'),
                            ],
                          ),
                          if (complete < s.requirements.length)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () =>
                                    state.completeAllDocs(s.id, s.requirements),
                                icon: const Icon(Icons.done_all, size: 18),
                                label: const Text('Mark all done'),
                              ),
                            ),
                          LinearProgressIndicator(value: readiness),
                        ],
                      ),
                    );
                  }),
                  ...s.requirements.map((doc) => CheckboxListTile(
                        value: state.isDocDone(s.id, doc),
                        onChanged: (_) => state.toggleDoc(s.id, doc),
                        title: Text(doc),
                      )),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ScholarshipDetailsScreen(
                                state: state, scholarship: s))),
                    child: const Text('View scholarship'),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
