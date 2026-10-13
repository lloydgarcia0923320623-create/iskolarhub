import 'package:flutter/material.dart';
import 'models/student.dart';
import 'models/income_bracket.dart';
import '../services/app_state.dart';

class ProfileScreen extends StatefulWidget {
  final AppState state;
  const ProfileScreen({super.key, required this.state});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController name, course, gwa;
  final formKey = GlobalKey<FormState>();
  int year = 1;
  IncomeBracket? incomeBracket;

  @override
  void initState() {
    super.initState();
    final s = widget.state.student;
    name = TextEditingController(text: s.name);
    course = TextEditingController(text: s.course);
    gwa = TextEditingController(text: s.gwa == 0 ? '' : s.gwa.toString());
    incomeBracket = s.incomeBracket ??
        (s.householdIncome > 0
            ? IncomeBracket.fromMonthlyIncome(s.householdIncome)
            : null);
    year = s.yearLevel;
  }

  @override
  void dispose() {
    name.dispose();
    course.dispose();
    gwa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = [
      name.text.trim().isNotEmpty,
      course.text.trim().isNotEmpty,
      gwa.text.trim().isNotEmpty,
      incomeBracket != null,
    ].where((value) => value).length;
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Student Profile',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const Text(
              'Your profile is used only for preliminary scholarship matching.'),
          const SizedBox(height: 20),
          TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your full name'
                  : null),
          const SizedBox(height: 12),
          TextFormField(
              controller: course,
              decoration: const InputDecoration(
                  labelText: 'Course',
                  hintText: 'e.g. BS Computer Engineering'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your course'
                  : null),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: year,
            decoration: const InputDecoration(labelText: 'Year Level'),
            items: [1, 2, 3, 4]
                .map((v) => DropdownMenuItem(value: v, child: Text('Year $v')))
                .toList(),
            onChanged: (v) => setState(() => year = v ?? 1),
          ),
          const SizedBox(height: 12),
          TextFormField(
              controller: gwa,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'GWA', hintText: 'e.g. 1.75'),
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed <= 0 || parsed > 5) {
                  return 'Enter a GWA between 1.00 and 5.00';
                }
                return null;
              }),
          const SizedBox(height: 12),
          DropdownButtonFormField<IncomeBracket>(
            initialValue: incomeBracket,
            decoration: const InputDecoration(
              labelText: 'Monthly Household Income Bracket',
              helperText:
                  'Matching uses the bracket’s upper limit to avoid overstating eligibility.',
            ),
            items: IncomeBracket.values
                .map((bracket) => DropdownMenuItem(
                      value: bracket,
                      child: Text(bracket.label),
                    ))
                .toList(),
            validator: (value) =>
                value == null ? 'Select an income bracket' : null,
            onChanged: (value) => setState(() => incomeBracket = value),
          ),
          const SizedBox(height: 20),
          Text('$completed/4 profile details complete',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: completed / 4),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final s = Student(
                name: name.text.trim(),
                course: course.text.trim(),
                yearLevel: year,
                gwa: double.tryParse(gwa.text) ?? 0,
                householdIncome: incomeBracket?.upperBound ?? 0,
                incomeBracket: incomeBracket,
              );
              widget.state.updateStudent(s);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile saved.')));
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Profile'),
          ),
          const SizedBox(height: 18),
          const Card(
              elevation: 0,
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'Note: Matching is preliminary. Final eligibility, document verification, and approval remain with the scholarship provider.'))),
        ],
      ),
    );
  }
}
