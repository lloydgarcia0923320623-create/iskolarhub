import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../services/app_state.dart';
import '../widgets/iskolarhub_mark.dart';
import '../constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  final AppState state;
  const LoginScreen({super.key, required this.state});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool creatingAccount = false;
  bool obscurePassword = true;
  bool loading = false;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Widget _reveal(double start, Widget child) {
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, (start + 0.4).clamp(0, 1),
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

  Future<void> _login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    setState(() => loading = true);
    final result = await widget.state.login(
      email: email.text.trim(),
      password: password.text,
      createAccount: creatingAccount,
    );
    if (!mounted) return;
    setState(() => loading = false);
    if (result != true) {
      const messages = {
        'verification-sent':
            'Account created. Check your email and verify it before signing in.',
        'verification-required':
            'Verify your email first. We sent a new verification link.',
        'weak-password':
            'Use at least 12 characters with uppercase, lowercase, a number, and a symbol.',
        'account-restricted':
            'This account cannot be used as a student account. Contact an administrator.',
        'auth:email-already-in-use':
            'Account setup could not be completed. Check your details and try again.',
        'auth:invalid-email': 'Enter a valid email address.',
        'auth:too-many-requests':
            'Too many attempts. Wait a while before trying again.',
        'auth:network-request-failed':
            'Could not connect to the authentication service. Check your connection.',
        'auth:operation-not-allowed':
            'Email/password sign-in is not enabled in Firebase yet.',
      };
      final message = messages[result] ??
          (result.toString().startsWith('auth:')
              ? 'Authentication could not be completed. Please try again.'
              : 'Email or password is incorrect.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      if (result == 'verification-sent' || result == 'verification-required') {
        confirmPassword.clear();
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => loading = true);
    final result = await widget.state.loginWithGoogle();
    if (!mounted) return;
    setState(() => loading = false);
    if (result == true || result == 'canceled') return;
    final message = result == 'admin-account'
        ? 'This Google account is registered as an administrator.'
        : 'Google sign-in could not be completed.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildSpaceBackground()),
          const Positioned.fill(
            child: ColoredBox(color: Color(0x990F172A)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF334155).withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _reveal(
                            0,
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const IskolarHubMark(
                                size: 58,
                                color: Colors.white,
                                accentColor: Color(0xFF818CF8),
                              ),
                            )),
                        const SizedBox(height: 18),
                        _reveal(
                            0.1,
                            const Text('IskolarHub',
                                style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE2E8F0)))),
                        _reveal(
                            0.2,
                            Text(
                                creatingAccount
                                    ? 'Create your student account. Email verification is required.'
                                    : 'Sign in to continue to IskolarHub.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 14,
                                ))),
                        const SizedBox(height: 34),
                        _reveal(
                            0.3,
                            TextFormField(
                                controller: email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style:
                                    const TextStyle(color: Color(0xFFFFFFFF)),
                                decoration: const InputDecoration(
                                    labelText: 'Email address',
                                    prefixIcon: Icon(Icons.email_outlined)),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter your email address';
                                  }
                                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(value.trim())) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                })),
                        const SizedBox(height: 12),
                        _reveal(
                            0.4,
                            TextFormField(
                                controller: password,
                                obscureText: obscurePassword,
                                autofillHints: [
                                  creatingAccount
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                style:
                                    const TextStyle(color: Color(0xFFFFFFFF)),
                                decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                        tooltip: obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: () => setState(() =>
                                            obscurePassword = !obscurePassword),
                                        icon: Icon(obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined))),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter your password';
                                  }
                                  if (creatingAccount &&
                                      !AppState.isStrongPassword(value)) {
                                    return 'Use 12+ characters with uppercase, lowercase, a number, and a symbol';
                                  }
                                  return null;
                                })),
                        if (creatingAccount) ...[
                          const SizedBox(height: 12),
                          _reveal(
                            0.45,
                            TextFormField(
                              controller: confirmPassword,
                              obscureText: obscurePassword,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(Icons.lock_reset_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirm your password';
                                }
                                if (value != password.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: loading ? null : _login,
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : Text(creatingAccount
                                      ? 'Create Student Account'
                                      : 'Sign In'),
                            )),
                        if (!creatingAccount)
                          TextButton(
                            onPressed: loading ? null : _showPasswordHelp,
                            child: const Text('Forgot password?'),
                          ),
                        const SizedBox(height: 10),
                        TextButton(
                            onPressed: loading
                                ? null
                                : () => setState(
                                    () => creatingAccount = !creatingAccount),
                            child: Text(creatingAccount
                                ? 'Already have an account? Sign in'
                                : 'New here? Create an account')),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: loading ? null : _loginWithGoogle,
                            icon: const Icon(Icons.account_circle_outlined),
                            label: const Text('Continue with Google'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceBackground() {
    final runningFlutterTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final supportsRive = !runningFlutterTest &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!supportsRive) return const _LiveStudyBackdrop();
    return const ColoredBox(
      color: Color(0xFF0F172A),
      child: RiveAnimation.asset(
        'assets/animations/3353-7046-space-background.riv',
        fit: BoxFit.cover,
      ),
    );
  }

  Future<void> _showPasswordHelp() async {
    final recoveryEmail = email.text.trim();
    if (recoveryEmail.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(recoveryEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your account email first.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Forgot password?'),
        content: const Text(
          'If an account exists for this address, Firebase will send it a password reset link.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send reset link'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => loading = true);
    final error = await widget.state.sendPasswordResetEmail(recoveryEmail);
    if (!mounted) return;
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error == null
            ? 'If an account exists for this address, a password reset link has been sent.'
            : 'Could not send a reset link. Check your connection and try again.'),
      ),
    );
  }
}

class _LiveStudyBackdrop extends StatefulWidget {
  const _LiveStudyBackdrop();

  @override
  State<_LiveStudyBackdrop> createState() => _LiveStudyBackdropState();
}

class _LiveStudyBackdropState extends State<_LiveStudyBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: AnimationDurations.continuous,
    );
    _startTimer = Timer(AnimationDurations.extraSlow, () {
      if (mounted) _motion.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, child) => CustomPaint(
        painter: _StudyBackdropPainter(_motion.value),
      ),
    );
  }
}

class _StudyBackdropPainter extends CustomPainter {
  final double progress;
  const _StudyBackdropPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final phase = progress * math.pi * 2;
    final glowCenter = Offset(
      size.width * (0.18 + math.sin(phase) * 0.06),
      size.height * (0.22 + math.cos(phase * 0.7) * 0.04),
    );
    canvas.drawCircle(
      glowCenter,
      size.width * 0.58,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0x336366F1),
            Color(0x0F6366F1),
            Color(0x006366F1),
          ],
          stops: [0, 0.45, 1],
        ).createShader(
            Rect.fromCircle(center: glowCenter, radius: size.width * 0.58)),
    );

    final secondaryGlowCenter = Offset(
      size.width * (0.75 + math.cos(phase * 1.3) * 0.08),
      size.height * (0.15 + math.sin(phase * 0.9) * 0.05),
    );
    final pulse = (math.sin(phase * 2) + 1) / 2;
    canvas.drawCircle(
      secondaryGlowCenter,
      size.width * 0.35 * pulse,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0x2410B981),
            Color(0x0A10B981),
            Color(0x0010B981),
          ],
          stops: [0, 0.5, 1],
        ).createShader(Rect.fromCircle(
            center: secondaryGlowCenter, radius: size.width * 0.35 * pulse)),
    );

    final gridPaint = Paint()
      ..color = const Color(0x156366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width + size.height; x += 34) {
      canvas.drawLine(
        Offset(x + progress * 28, 0),
        Offset(x - size.height + progress * 28, size.height),
        gridPaint,
      );
    }
    for (var y = 0.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final orbitPaint = Paint()
      ..color = const Color(0x1A6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final orbitCenter = Offset(size.width * 0.82, size.height * 0.78);
    for (var ring = 0; ring < 3; ring++) {
      canvas.save();
      canvas.translate(orbitCenter.dx, orbitCenter.dy);
      canvas.rotate(-0.35 + ring * 0.08 + phase * 0.03);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 170 + ring * 32,
          height: 54 + ring * 18,
        ),
        orbitPaint..color = const Color(0x126366F1),
      );
      canvas.restore();
    }

    for (var i = 0; i < 3; i++) {
      final orbitPhase = phase + (i * 2.094);
      final particleOffset = Offset(
        orbitCenter.dx + math.cos(orbitPhase) * (92 + i * 20),
        orbitCenter.dy + math.sin(orbitPhase) * (30 + i * 15),
      );

      canvas.drawCircle(
        particleOffset,
        3.5 + (math.sin(phase * 3 + i) + 1) * 1.5,
        Paint()..color = const Color(0xFF6366F1).withValues(alpha: 0.6),
      );

      canvas.drawCircle(
        particleOffset,
        8,
        Paint()..color = const Color(0xFF6366F1).withValues(alpha: 0.2),
      );
    }

    for (var i = 0; i < 8; i++) {
      final floatPhase = phase * 0.7 + (i * 0.785);
      final floatY = size.height * (0.3 + math.sin(floatPhase + i) * 0.3);
      final floatX = size.width *
          (0.1 + (i % 4) * 0.25 + math.cos(floatPhase * 0.5 + i) * 0.08);

      canvas.drawCircle(
        Offset(floatX, floatY),
        2,
        Paint()
          ..color = const Color(0xFF6366F1).withValues(
            alpha: 0.3 * (math.sin(phase * 2 + i) + 1) / 2,
          ),
      );
    }

    final centerPulse = (math.sin(phase * 1.5) + 1) / 2;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      15 * centerPulse,
      Paint()
        ..color = const Color(0xFF6366F1).withValues(alpha: 0.15 * centerPulse),
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      6,
      Paint()..color = const Color(0xFF6366F1),
    );
  }

  @override
  bool shouldRepaint(_StudyBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
