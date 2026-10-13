import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/iskolarhub_mark.dart';
import 'constants/app_constants.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kReleaseMode
        ? const AndroidPlayIntegrityProvider()
        : const AndroidDebugProvider(),
    providerApple: kReleaseMode
        ? const AppleAppAttestProvider()
        : const AppleDebugProvider(),
  );
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
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Color(0xFFE2E8F0),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF1E293B),
          indicatorColor: Color(0xFF6366F1),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w500),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Color(0xFFE2E8F0),
          titleTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
          subtitleTextStyle: TextStyle(color: Color(0xFFCBD5E1)),
          iconColor: Color(0xFFE2E8F0),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF6366F1);
            }
            return const Color(0xFF334155);
          }),
          checkColor: const WidgetStatePropertyAll(Color(0xFFFFFFFF)),
        ),
        chipTheme: const ChipThemeData(
          labelStyle: TextStyle(color: Color(0xFFE2E8F0)),
          secondaryLabelStyle: TextStyle(color: Color(0xFFFFFFFF)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF0F172A),
          labelStyle: TextStyle(color: Color(0xFFE2E8F0)),
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          helperStyle: TextStyle(color: Color(0xFFCBD5E1)),
          errorStyle: TextStyle(color: Color(0xFFEF4444)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          prefixIconColor: Color(0xFFE2E8F0),
          suffixIconColor: Color(0xFFE2E8F0),
        ),
        textTheme: const TextTheme(
          headlineLarge:
              TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
          headlineMedium:
              TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
          headlineSmall:
              TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Color(0xFFFFFFFF)),
          titleMedium: TextStyle(color: Color(0xFFFFFFFF)),
          titleSmall: TextStyle(color: Color(0xFFE2E8F0)),
          bodyLarge: TextStyle(color: Color(0xFFE2E8F0)),
          bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
          bodySmall: TextStyle(color: Color(0xFFCBD5E1)),
          labelLarge: TextStyle(color: Color(0xFFFFFFFF)),
          labelMedium: TextStyle(color: Color(0xFFE2E8F0)),
          labelSmall: TextStyle(color: Color(0xFFCBD5E1)),
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
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
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
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                blurRadius: 34,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const IskolarHubMark(
            size: 60,
            color: Colors.white,
            accentColor: Color(0xFF818CF8),
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
          color: Color(0xFFE2E8F0),
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
        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
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
          backgroundColor: const Color(0x226366F1),
          valueColor: const AlwaysStoppedAnimation<Color>(
            Color(0xFF10B981),
          ),
        ),
      ),
    );
  }
}
