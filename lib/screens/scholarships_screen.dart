import 'package:flutter/material.dart';
import '../services/app_state.dart';
import 'models/scholarship.dart';
import '../scholarship_details_screen.dart';

class ScholarshipsScreen extends StatefulWidget {
  final AppState state;
  const ScholarshipsScreen({super.key, required this.state});
  @override
  State<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends State<ScholarshipsScreen> {
  String query = '';
  bool matchesOnly = false;

  @override
  Widget build(BuildContext context) {
    final list = widget.state.scholarships.where((s) {
      if (s.isArchived) return false;
      final q = query.toLowerCase();
      final text = '${s.name} ${s.provider} ${s.description}'.toLowerCase();
      return text.contains(q) && (!matchesOnly || widget.state.qualifies(s));
    }).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Search scholarships...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Saved scholarship records are cached locally for offline viewing and may be out of date.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          FilterChip(
            selected: matchesOnly,
            onSelected: (v) => setState(() => matchesOnly = v),
            label: const Text('Only my matches'),
            avatar: const Icon(Icons.auto_awesome, size: 17),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: list.isEmpty
            ? const Center(child: Text('No scholarships found.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _ScholarshipCard(state: widget.state, s: list[i]),
              ),
      ),
    ]);
  }
}

class _ScholarshipCard extends StatelessWidget {
  final AppState state;
  final Scholarship s;
  const _ScholarshipCard({required this.state, required this.s});

  @override
  Widget build(BuildContext context) {
    final match = state.qualifies(s);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ScholarshipDetailsScreen(state: state, scholarship: s))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(child: Icon(Icons.school_outlined)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(s.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(s.provider,
                        style: const TextStyle(color: Color(0xFFCBD5E1))),
                  ])),
              IconButton(
                onPressed: () => state.toggleSaved(s.id),
                icon: Icon(state.saved.contains(s.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border),
              ),
            ]),
            const SizedBox(height: 10),
            Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(children: [
              _Tag(text: 'GWA ≤ ${s.minGwa.toStringAsFixed(2)}'),
              const SizedBox(width: 6),
              if (match) const _Tag(text: 'MATCH'),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)));
}
