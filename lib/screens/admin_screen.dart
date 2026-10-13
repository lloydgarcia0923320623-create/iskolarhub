import 'package:flutter/material.dart';
import 'models/scholarship.dart';
import '../services/app_state.dart';
import '../constants/app_constants.dart';
import 'admin_scholarship_editor.dart';
import 'scholarship_reports_panel.dart';

class AdminScreen extends StatefulWidget {
  final AppState state;

  const AdminScreen({
    super.key,
    required this.state,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredScholarships = _filterScholarships();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Scholarship Management',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage scholarship listings and review student information reports.',
          ),
          const SizedBox(height: 18),
          _buildStatsRow(),
          const SizedBox(height: 14),
          _buildSearchField(),
          const SizedBox(height: 14),
          _buildAddButton(),
          const SizedBox(height: 14),
          ScholarshipReportsPanel(state: widget.state),
          const SizedBox(height: 14),
          ..._buildScholarshipCards(filteredScholarships),
        ],
      ),
    );
  }

  List<Scholarship> _filterScholarships() {
    return widget.state.scholarships.where((scholarship) {
      final searchText =
          '${scholarship.name} ${scholarship.provider}'.toLowerCase();
      return searchText.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildStatsRow() {
    final totalCount = widget.state.scholarships.length;
    final matchingCount = widget.state.scholarships
        .where((scholarship) => widget.state.qualifies(scholarship))
        .length;

    return Row(
      children: [
        Expanded(
          child: _AdminStat(
            value: '$totalCount',
            label: 'Listings',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AdminStat(
            value: '$matchingCount',
            label: 'Matches',
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
      decoration: const InputDecoration(
        hintText: 'Search listings...',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  Widget _buildAddButton() {
    return FilledButton.icon(
      onPressed: () => _showAddScholarshipDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('Add Scholarship'),
    );
  }

  List<Widget> _buildScholarshipCards(List<Scholarship> scholarships) {
    return scholarships.map((scholarship) {
      return Card(
        elevation: 0,
        child: ListTile(
          title: Text(scholarship.name),
          subtitle: Text(
              '${scholarship.provider} • ${scholarship.verificationStatus.label}'),
          trailing: Wrap(
            children: [
              IconButton(
                tooltip: 'Edit scholarship',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showEditScholarshipDialog(scholarship),
              ),
              IconButton(
                tooltip: 'Delete scholarship',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteConfirmation(context, scholarship),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> _showEditScholarshipDialog(Scholarship scholarship) async {
    final updated = await showDialog<Scholarship>(
      context: context,
      builder: (_) => ScholarshipEditorDialog(scholarship: scholarship),
    );
    if (updated == null) return;
    widget.state.updateScholarship(updated);
    try {
      final synced = await widget.state.syncScholarshipToCloud(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(synced
              ? 'Scholarship record updated centrally.'
              : 'Updated on this device. Sign in with an authorized admin account to sync centrally.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated locally, but central sync failed: $error'),
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    Scholarship scholarship,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete scholarship?'),
        content: Text('Remove "${scholarship.name}" from the directory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    widget.state.deleteScholarship(scholarship.id);
    try {
      final synced =
          await widget.state.deleteScholarshipFromCloud(scholarship.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(synced
              ? 'Scholarship removed from the directory.'
              : 'Removed from this device. Sign in with an authorized admin account to sync centrally.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed locally, but central deletion failed: $error'),
        ),
      );
    }
  }

  Future<void> _showAddScholarshipDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final providerController = TextEditingController();
    final descriptionController = TextEditingController();
    final gwaController = TextEditingController(text: '2.00');
    final incomeController = TextEditingController(text: '30000');
    final coursesController = TextEditingController();
    final descriptiveRequirementsController = TextEditingController();
    final benefitsController = TextEditingController();
    final periodController = TextEditingController();
    final applicationUrlController = TextEditingController();
    final sourceUrlController = TextEditingController();
    final requirementsController = TextEditingController(
      text: 'Latest grades, Certificate of enrollment, Valid ID',
    );
    final formKey = GlobalKey<FormState>();
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 30));
    final selectedYears = <int>{1, 2, 3, 4};

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add Scholarship'),
          content: SingleChildScrollView(
            child: _buildScholarshipForm(
              formKey: formKey,
              nameController: nameController,
              providerController: providerController,
              descriptionController: descriptionController,
              gwaController: gwaController,
              incomeController: incomeController,
              coursesController: coursesController,
              requirementsController: requirementsController,
              descriptiveRequirementsController:
                  descriptiveRequirementsController,
              benefitsController: benefitsController,
              periodController: periodController,
              applicationUrlController: applicationUrlController,
              sourceUrlController: sourceUrlController,
              selectedDeadline: selectedDeadline,
              selectedYears: selectedYears,
              onDeadlineTap: () async {
                final picked = await showDatePicker(
                  context: dialogContext,
                  initialDate: selectedDeadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (picked != null) {
                  setDialogState(() => selectedDeadline = picked);
                }
              },
              onYearToggle: (year, selected) {
                setDialogState(() {
                  if (selected) {
                    selectedYears.add(year);
                  } else {
                    selectedYears.remove(year);
                  }
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                if (selectedYears.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Select at least one year level.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    await _addNewScholarship(
      nameController: nameController,
      providerController: providerController,
      descriptionController: descriptionController,
      gwaController: gwaController,
      incomeController: incomeController,
      coursesController: coursesController,
      requirementsController: requirementsController,
      descriptiveRequirementsController: descriptiveRequirementsController,
      benefitsController: benefitsController,
      periodController: periodController,
      applicationUrlController: applicationUrlController,
      sourceUrlController: sourceUrlController,
      deadline: selectedDeadline,
      yearLevels: selectedYears,
    );
  }

  Widget _buildScholarshipForm({
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required TextEditingController providerController,
    required TextEditingController descriptionController,
    required TextEditingController gwaController,
    required TextEditingController incomeController,
    required TextEditingController coursesController,
    required TextEditingController requirementsController,
    required TextEditingController descriptiveRequirementsController,
    required TextEditingController benefitsController,
    required TextEditingController periodController,
    required TextEditingController applicationUrlController,
    required TextEditingController sourceUrlController,
    required DateTime selectedDeadline,
    required Set<int> selectedYears,
    required VoidCallback onDeadlineTap,
    required void Function(int year, bool selected) onYearToggle,
  }) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Scholarship Name'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a name' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: providerController,
            decoration: const InputDecoration(labelText: 'Provider'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: descriptionController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: gwaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Maximum GWA (1.00\u20135.00)'),
            validator: (v) {
              final parsed = double.tryParse(v ?? '');
              if (parsed == null || parsed <= 0 || parsed > 5) {
                return 'Enter a GWA between 1.00 and 5.00';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: incomeController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Maximum Household Income'),
            validator: (v) {
              final parsed = double.tryParse(v ?? '');
              return parsed == null || parsed <= 0
                  ? 'Enter a valid maximum income'
                  : null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: coursesController,
            decoration: const InputDecoration(
              labelText: 'Eligible Courses (comma-separated, blank = all)',
              hintText: 'e.g. Computer Science, Information Technology',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: requirementsController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Requirements (comma-separated)',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Enter at least one requirement'
                : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: descriptiveRequirementsController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Other eligibility conditions (comma-separated)',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: benefitsController,
            decoration: const InputDecoration(labelText: 'Benefits'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: periodController,
            decoration: const InputDecoration(labelText: 'Application period'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: applicationUrlController,
            decoration:
                const InputDecoration(labelText: 'Official application URL'),
            validator: _validateOptionalUrl,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: sourceUrlController,
            decoration: const InputDecoration(labelText: 'Official source URL'),
            validator: _validateOptionalUrl,
          ),
          const SizedBox(height: 14),
          const Text('Deadline', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: onDeadlineTap,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              '${selectedDeadline.year}-'
              '${selectedDeadline.month.toString().padLeft(2, '0')}-'
              '${selectedDeadline.day.toString().padLeft(2, '0')}',
            ),
          ),
          const SizedBox(height: 14),
          const Text('Eligible Year Levels',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [1, 2, 3, 4].map((year) {
              final selected = selectedYears.contains(year);
              return FilterChip(
                label: Text('Year $year'),
                selected: selected,
                onSelected: (v) => onYearToggle(year, v),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewScholarship({
    required TextEditingController nameController,
    required TextEditingController providerController,
    required TextEditingController descriptionController,
    required TextEditingController gwaController,
    required TextEditingController incomeController,
    required TextEditingController coursesController,
    required TextEditingController requirementsController,
    required TextEditingController descriptiveRequirementsController,
    required TextEditingController benefitsController,
    required TextEditingController periodController,
    required TextEditingController applicationUrlController,
    required TextEditingController sourceUrlController,
    required DateTime deadline,
    required Set<int> yearLevels,
  }) async {
    final providerName = providerController.text.trim().isEmpty
        ? 'Scholarship Provider'
        : providerController.text.trim();

    final courses = coursesController.text
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    final requirements = requirementsController.text
        .split(',')
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .toList();

    final sortedYears = yearLevels.toList()..sort();

    final newScholarship = Scholarship(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      provider: providerName,
      description: descriptionController.text.trim(),
      minGwa: double.tryParse(gwaController.text) ?? 2.0,
      courses: courses,
      yearLevels: sortedYears,
      maxIncome: double.tryParse(incomeController.text) ?? 30000,
      deadline: deadline,
      requirements: requirements.isEmpty
          ? const ['Latest grades', 'Certificate of enrollment', 'Valid ID']
          : requirements,
      applicationUrl: applicationUrlController.text.trim(),
      benefits: benefitsController.text.trim(),
      applicationPeriod: periodController.text.trim(),
      sourceUrl: sourceUrlController.text.trim(),
      descriptiveRequirements: descriptiveRequirementsController.text
          .split(',')
          .map((r) => r.trim())
          .where((r) => r.isNotEmpty)
          .toList(),
    );

    widget.state.addScholarship(newScholarship);
    try {
      final synced = await widget.state.syncScholarshipToCloud(newScholarship);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(synced
              ? 'Scholarship saved to the central directory.'
              : 'Saved on this device. Sign in with an authorized admin account to sync centrally.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved locally, but central sync failed: $error'),
        ),
      );
    }
  }

  String? _validateOptionalUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    return uri == null ||
            (uri.scheme != 'https' && uri.scheme != 'http') ||
            uri.host.isEmpty
        ? 'Enter a valid http or https URL'
        : null;
  }
}

class _AdminStat extends StatelessWidget {
  final String value;
  final String label;

  const _AdminStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorValues.statCardBackground,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ColorValues.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: ColorValues.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
