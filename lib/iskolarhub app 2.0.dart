import 'package:flutter/material.dart';
import 'services/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/iskolarhub_mark.dart';
import 'constants/app_constants.dart';

void main() {
  runApp(const IskolarHubApp());
}

class IskolarHubApp extends StatefulWidget {
  const IskolarHubApp({super.key});

  @override
  State<IskolarHubApp> createState() => _IskolarHubAppState();
}

class _IskolarHubAppState extends State<IskolarHubApp> {
  final state = AppState();
  bool opening = true;

  @override
  void initState() {
    super.initState();
    state.load().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) => _buildMaterialApp(context),
    );
  }

  Widget _buildMaterialApp(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IskolarHub',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087E8B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFEAF2F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF102A2A),
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE4EBE7)),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF0C2024),
          indicatorColor: Color(0xFF0EC6B5),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: Colors.white),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    return AnimatedSwitcher(
      duration: AnimationDurations.medium,
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: state.loggedIn
          ? HomeScreen(key: const ValueKey('home'), state: state)
          : opening
              ? _OpeningScreen(
                  key: const ValueKey('opening'),
                  onFinished: () => setState(() => opening = false),
                )
              : LoginScreen(key: const ValueKey('login'), state: state),
    );
  }
}

class _OpeningScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const _OpeningScreen({super.key, required this.onFinished});

  @override
  State<_OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<_OpeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: AnimationDurations.continuous,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          widget.onFinished();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _animation,
      curve: Curves.easeOutCubic,
    );
    return Scaffold(
      body: AnimatedBuilder(
        animation: curve,
        builder: (context, child) => _buildOpeningContent(curve),
      ),
    );
  }

  Widget _buildOpeningContent(CurvedAnimation curve) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A2A), Color(0xFF16464A), Color(0xFF0C2024)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnimatedLogo(curve),
            const SizedBox(height: 24),
            _buildBrandTitle(curve),
            const SizedBox(height: 8),
            _buildTagline(curve),
            const SizedBox(height: 34),
            _buildLoadingIndicator(curve),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(CurvedAnimation curve) {
    return Transform.scale(
      scale: AnimationCurves.opacityBlend +
          curve.value * AnimationCurves.curveValueBlend,
      child: Opacity(
        opacity: curve.value,
        child: Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            color: const Color(0xFF0EC6B5),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0EC6B5).withValues(alpha: 0.3),
                blurRadius: 34,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const IskolarHubMark(
            size: 60,
            color: Color(0xFF102A2A),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandTitle(CurvedAnimation curve) {
    return Opacity(
      opacity: curve.value,
      child: const Text(
        'IskolarHub',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTagline(CurvedAnimation curve) {
    return Opacity(
      opacity: (curve.value - 0.2).clamp(0.0, 1.0),
      child: const Text(
        'Find your next opportunity.',
        style: TextStyle(color: Color(0xB8D5E8E4), fontSize: 14),
      ),
    );
  }

  Widget _buildLoadingIndicator(CurvedAnimation curve) {
    return SizedBox(
      width: 104,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: curve.value,
          minHeight: 4,
          backgroundColor: const Color(0x3322B8AD),
          valueColor: const AlwaysStoppedAnimation<Color>(
            Color(0xFFE7C65B),
          ),
        ),
      ),
    );
  }
}
