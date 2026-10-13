import 'package:flutter/material.dart';
import '../screens/models/scholarship_report.dart';
import '../services/app_state.dart';

class ScholarshipReportsPanel extends StatefulWidget {
  final AppState state;

  const ScholarshipReportsPanel({super.key, required this.state});

  @override
  State<ScholarshipReportsPanel> createState() =>
      _ScholarshipReportsPanelState();
}

class _ScholarshipReportsPanelState extends State<ScholarshipReportsPanel> {
  late Future<List<ScholarshipReport>> _reports;

  @override
  void initState() {
    super.initState();
    _reports = widget.state.getScholarshipReports();
  }

  void _reload() {
    setState(() => _reports = widget.state.getScholarshipReports());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.flag_outlined),
        title: const Text('Student information reports'),
        subtitle: const Text('Review reports about outdated listings'),
        onExpansionChanged: (expanded) {
          if (expanded) _reload();
        },
        children: [
          FutureBuilder<List<ScholarshipReport>>(
            future: _reports,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Could not load reports. Confirm administrator access and connection, then reopen this section.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No scholarship information reports yet.'),
                );
              }
              return Column(
                children: snapshot.data!
                    .map((report) => _ReportCard(
                          report: report,
                          onUpdated: _reload,
                          state: widget.state,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final ScholarshipReport report;
  final AppState state;
  final VoidCallback onUpdated;

  const _ReportCard({
    required this.report,
    required this.state,
    required this.onUpdated,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  late ReportStatus _status = widget.report.status;
  bool _saving = false;

  Future<void> _updateStatus(ReportStatus? status) async {
    if (status == null || status == _status || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.state.updateScholarshipReport(
        widget.report,
        status,
        widget.report.reviewerNote,
      );
      if (!mounted) return;
      setState(() => _status = status);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report review status saved.')),
      );
      widget.onUpdated();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not update this report. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: true,
      title: Text(widget.report.scholarshipId),
      subtitle: Text(
        '${widget.report.note}\n'
        'Submitted ${widget.report.createdAt.toLocal()}'
        '${widget.report.reviewerNote.isEmpty ? '' : '\nReview note: ${widget.report.reviewerNote}'}',
      ),
      trailing: SizedBox(
        width: 145,
        child: DropdownButton<ReportStatus>(
          value: _status,
          isExpanded: true,
          onChanged: _saving ? null : _updateStatus,
          items: ReportStatus.values
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.label, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
