import 'package:flutter/material.dart';
import 'models/scholarship.dart';
import 'models/verification_status.dart';

class ScholarshipEditorDialog extends StatefulWidget {
  final Scholarship scholarship;

  const ScholarshipEditorDialog({super.key, required this.scholarship});

  @override
  State<ScholarshipEditorDialog> createState() =>
      _ScholarshipEditorDialogState();
}

class _ScholarshipEditorDialogState extends State<ScholarshipEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _provider;
  late final TextEditingController _description;
  late final TextEditingController _gwa;
  late final TextEditingController _income;
  late final TextEditingController _courses;
  late final TextEditingController _requirements;
  late final TextEditingController _descriptiveRequirements;
  late final TextEditingController _benefits;
  late final TextEditingController _period;
  late final TextEditingController _applicationUrl;
  late final TextEditingController _sourceUrl;
  late DateTime _deadline;
  late VerificationStatus _verificationStatus;
  late DateTime? _lastVerifiedAt;
  late Set<int> _yearLevels;

  @override
  void initState() {
    super.initState();
    final scholarship = widget.scholarship;
    _name = TextEditingController(text: scholarship.name);
    _provider = TextEditingController(text: scholarship.provider);
    _description = TextEditingController(text: scholarship.description);
    _gwa = TextEditingController(text: scholarship.minGwa.toString());
    _income = TextEditingController(text: scholarship.maxIncome.toString());
    _courses = TextEditingController(text: scholarship.courses.join(', '));
    _requirements =
        TextEditingController(text: scholarship.requirements.join(', '));
    _descriptiveRequirements = TextEditingController(
        text: scholarship.descriptiveRequirements.join(', '));
    _benefits = TextEditingController(text: scholarship.benefits);
    _period = TextEditingController(text: scholarship.applicationPeriod);
    _applicationUrl = TextEditingController(text: scholarship.applicationUrl);
    _sourceUrl = TextEditingController(text: scholarship.sourceUrl);
    _deadline = scholarship.deadline;
    _verificationStatus = scholarship.verificationStatus;
    _lastVerifiedAt = scholarship.lastVerifiedAt;
    _yearLevels = scholarship.yearLevels.toSet();
  }

  @override
  void dispose() {
    _name.dispose();
    _provider.dispose();
    _description.dispose();
    _gwa.dispose();
    _income.dispose();
    _courses.dispose();
    _requirements.dispose();
    _descriptiveRequirements.dispose();
    _benefits.dispose();
    _period.dispose();
    _applicationUrl.dispose();
    _sourceUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Scholarship Record'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(_name, 'Scholarship Name', required: true),
                _textField(_provider, 'Provider', required: true),
                _textField(_description, 'Description', maxLines: 3),
                _textField(
                  _gwa,
                  'Maximum GWA (1.00–5.00)',
                  number: true,
                  validator: (value) {
                    final number = double.tryParse(value ?? '');
                    return number == null || number <= 0 || number > 5
                        ? 'Enter a GWA from 1.00 to 5.00'
                        : null;
                  },
                ),
                _textField(
                  _income,
                  'Maximum monthly household income',
                  number: true,
                  validator: (value) {
                    final number = double.tryParse(value ?? '');
                    return number == null || number <= 0
                        ? 'Enter a valid income ceiling'
                        : null;
                  },
                ),
                _textField(_courses, 'Eligible courses (comma-separated; blank = all)'),
                _textField(_requirements, 'Documentary requirements (comma-separated)',
                    maxLines: 3,
                    validator: (value) => _split(value).isEmpty
                        ? 'Add at least one requirement'
                        : null),
                _textField(_descriptiveRequirements,
                    'Other eligibility conditions (comma-separated)',
                    maxLines: 3),
                _textField(_benefits, 'Benefits'),
                _textField(_period, 'Application period'),
                _textField(
                  _applicationUrl,
                  'Official application link',
                  validator: _validateOptionalUrl,
                ),
                _textField(
                  _sourceUrl,
                  'Official source / verification link',
                  validator: _validateOptionalUrl,
                ),
                const SizedBox(height: 8),
                const Text('Application deadline'),
                OutlinedButton.icon(
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                      '${_deadline.year}-${_deadline.month.toString().padLeft(2, '0')}-${_deadline.day.toString().padLeft(2, '0')}'),
                ),
                const SizedBox(height: 8),
                const Text('Eligible year levels (none = all)'),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 3, 4].map((year) {
                    return FilterChip(
                      label: Text('Year $year'),
                      selected: _yearLevels.contains(year),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _yearLevels.add(year);
                        } else {
                          _yearLevels.remove(year);
                        }
                      }),
                    );
                  }).toList(),
                ),
                DropdownButtonFormField<VerificationStatus>(
                  initialValue: _verificationStatus,
                  decoration:
                      const InputDecoration(labelText: 'Record status'),
                  items: VerificationStatus.values
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ))
                      .toList(),
                  onChanged: (status) {
                    if (status != null) {
                      setState(() {
                        _verificationStatus = status;
                        if (status == VerificationStatus.verified) {
                          _lastVerifiedAt = DateTime.now();
                        }
                      });
                    }
                  },
                ),
                if (_lastVerifiedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        'Last verified: ${_lastVerifiedAt!.year}-${_lastVerifiedAt!.month.toString().padLeft(2, '0')}-${_lastVerifiedAt!.day.toString().padLeft(2, '0')}'),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save changes'),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        minLines: maxLines > 1 ? 2 : null,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: validator ??
            (required
                ? (value) => value == null || value.trim().isEmpty
                    ? 'This field is required'
                    : null
                : null),
      ),
    );
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

  List<String> _split(String? value) => (value ?? '')
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) setState(() => _deadline = picked);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final verifiedAt = _verificationStatus == VerificationStatus.verified
        ? (_lastVerifiedAt ?? DateTime.now())
        : _lastVerifiedAt;
    Navigator.pop(
      context,
      Scholarship(
        id: widget.scholarship.id,
        name: _name.text.trim(),
        provider: _provider.text.trim(),
        description: _description.text.trim(),
        minGwa: double.parse(_gwa.text),
        courses: _split(_courses.text),
        yearLevels: _yearLevels.toList()..sort(),
        maxIncome: double.parse(_income.text),
        deadline: _deadline,
        requirements: _split(_requirements.text),
        applicationUrl: _applicationUrl.text.trim(),
        benefits: _benefits.text.trim(),
        applicationPeriod: _period.text.trim(),
        sourceUrl: _sourceUrl.text.trim(),
        verificationStatus: _verificationStatus,
        lastVerifiedAt: verifiedAt,
        descriptiveRequirements: _split(_descriptiveRequirements.text),
      ),
    );
  }
}
