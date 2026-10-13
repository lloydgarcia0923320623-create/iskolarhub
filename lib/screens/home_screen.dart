import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../constants/app_constants.dart';
import 'models/scholarship.dart';
import 'scholarships_screen.dart';
import 'profile_screen.dart';
import 'checklist_screen.dart';
import 'admin_screen.dart';
import '../scholarship_details_screen.dart';
import 'resources_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState state;
  const HomeScreen({super.key, required this.state});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(
          state: widget.state,
          onOpen: (s) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ScholarshipDetailsScreen(
                        state: widget.state, scholarship: s)));
          }),
      ScholarshipsScreen(state: widget.state),
      ChecklistScreen(
        state: widget.state,
        onBrowseScholarships: () => setState(() => index = 1),
      ),
      ProfileScreen(state: widget.state),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('IskolarHub',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Resources',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ResourcesScreen(state: widget.state))),
          ),
          if (widget.state.adminMode)
            IconButton(
              tooltip: 'Admin',
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AdminScreen(state: widget.state))),
            ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: AnimationDurations.standard,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(AnimationCurves.parallaxX, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(index),
          child: pages[index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (selectedIndex) {
          setState(() => index = selectedIndex);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Scholarships',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            label: 'Checklist',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again next time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.state.logout();
  }
}

class _Dashboard extends StatefulWidget {
  final AppState state;
  final void Function(Scholarship) onOpen;
  const _Dashboard({required this.state, required this.onOpen});

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) {
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(index * 0.1, (0.55 + index * 0.1).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qualified =
        widget.state.scholarships.where(widget.state.qualifies).toList();
    final upcoming =
        widget.state.scholarships.where((item) => !item.isArchived).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    final name = widget.state.student.name.isEmpty
        ? 'Student'
        : widget.state.student.name.split(' ').first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _reveal(
          0,
          Text('Hello, $name',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF))),
        ),
        _reveal(
            1,
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('A short list of opportunities worth your time.',
                  style: TextStyle(color: Color(0xFFE2E8F0))),
            )),
        const SizedBox(height: 20),
        _reveal(
            2,
            Row(children: [
              Expanded(
                  child: _StatCard(
                      icon: Icons.auto_awesome,
                      value: '${qualified.length}',
                      label: 'Matches')),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      icon: Icons.bookmark,
                      value: '${widget.state.saved.length}',
                      label: 'Saved')),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      icon: Icons.calendar_month,
                      value: '${upcoming.length}',
                      label: 'Available')),
            ])),
        const SizedBox(height: 26),
        _reveal(
            3,
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Your Matches',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF))),
              Text('${qualified.length} found',
                  style: const TextStyle(color: Color(0xFFCBD5E1))),
            ])),
        const SizedBox(height: 10),
        if (qualified.isEmpty)
          const _EmptyCard(
              text: 'Complete your profile to see scholarship matches.')
        else
          ...qualified.take(3).map((scholarship) => _reveal(
              4,
              _MiniScholarship(
                scholarship: scholarship,
                state: widget.state,
                onOpen: widget.onOpen,
              ))),
        const SizedBox(height: 22),
        const Text('Upcoming Deadlines',
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF))),
        const SizedBox(height: 10),
        ...upcoming.take(3).map((scholarship) => _reveal(
            5,
            _MiniScholarship(
              scholarship: scholarship,
              state: widget.state,
              onOpen: widget.onOpen,
            ))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniScholarship extends StatelessWidget {
  final Scholarship scholarship;
  final AppState state;
  final void Function(Scholarship) onOpen;

  const _MiniScholarship({
    required this.scholarship,
    required this.state,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => onOpen(scholarship),
        leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
        title: Text(
          scholarship.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)),
        ),
        subtitle: Text(
          '${scholarship.provider} • Deadline ${DateFormat('MMM d').format(scholarship.deadline)}',
          style: const TextStyle(color: Color(0xFFCBD5E1)),
        ),
        trailing: _buildSaveButton(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: child,
        ),
        child: Icon(
          key: ValueKey(state.saved.contains(scholarship.id)),
          state.saved.contains(scholarship.id)
              ? Icons.bookmark
              : Icons.bookmark_border,
        ),
      ),
      onPressed: () => state.toggleSaved(scholarship.id),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(text, style: const TextStyle(color: Color(0xFFE2E8F0))),
      ),
    );
  }
}
