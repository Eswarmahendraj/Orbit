import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../theme/aura_theme.dart';
import '../../widgets/vybe_logo.dart';
import 'signup_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _auth       = AuthService();
  bool _usePhone    = false;
  bool _loading     = false;
  bool _obscure     = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_usePhone) {
        await _auth.sendOtp(
          phone: '+91${_phoneCtrl.text.trim()}',
          onAutoVerified: (_) {},
          onCodeSent: (vId, _) => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => OtpScreen(
                        verificationId: vId,
                        name: '',
                        phone: '+91${_phoneCtrl.text.trim()}',
                      ))),
          onError: (e) => _err(e.message ?? 'Error'),
        );
      } else {
        await _auth.signInWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      }
    } catch (_) {
      _err('Invalid credentials. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AuraColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // ── Logo ──────────────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        const VybeLogo(size: 110)
                            .animate()
                            .fadeIn(duration: 800.ms)
                            .scale(begin: const Offset(0.7, 0.7)),
                        const SizedBox(height: 18),
                        const VybeTextLogo(fontSize: 38)
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 600.ms)
                            .slideY(begin: 0.3),
                        const SizedBox(height: 8),
                        const Text(
                          'Feel who\'s around.',
                          style: TextStyle(
                              color: AuraColors.textSecondary,
                              fontSize: 14,
                              letterSpacing: 0.5),
                        ).animate().fadeIn(delay: 500.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 52),

                  // ── Heading ───────────────────────────────────────────────
                  Text('Welcome back',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800))
                      .animate()
                      .fadeIn(delay: 400.ms),
                  const SizedBox(height: 6),
                  const Text('Sign in to your Vybe',
                      style: TextStyle(
                          color: AuraColors.textSecondary, fontSize: 14))
                      .animate()
                      .fadeIn(delay: 450.ms),

                  const SizedBox(height: 28),

                  // ── Toggle ────────────────────────────────────────────────
                  Row(children: [
                    _Chip(
                        label: 'Email',
                        selected: !_usePhone,
                        onTap: () => setState(() => _usePhone = false)),
                    const SizedBox(width: 10),
                    _Chip(
                        label: 'Mobile',
                        selected: _usePhone,
                        onTap: () => setState(() => _usePhone = true)),
                  ]).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 18),

                  // ── Fields ────────────────────────────────────────────────
                  if (!_usePhone) ...[
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.mail_outline,
                            color: AuraColors.textSecondary),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Enter a valid email'
                          : null,
                    ).animate().fadeIn(delay: 550.ms),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AuraColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AuraColors.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter password' : null,
                    ).animate().fadeIn(delay: 600.ms),
                  ] else
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        prefixText: '+91  ',
                        prefixIcon: Icon(Icons.phone_outlined,
                            color: AuraColors.textSecondary),
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      validator: (v) =>
                          v?.length != 10 ? 'Enter 10-digit number' : null,
                    ).animate().fadeIn(delay: 550.ms),

                  const SizedBox(height: 32),

                  // ── Gradient Sign In button ───────────────────────────────
                  _GradientButton(
                    loading: _loading,
                    label: _usePhone ? 'Send OTP' : 'Sign In',
                    onTap: _loading ? null : _submit,
                  ).animate().fadeIn(delay: 650.ms),

                  const SizedBox(height: 24),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("Don't have an account? ",
                        style:
                            TextStyle(color: AuraColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen())),
                      child: ShaderMask(
                        shaderCallback: (b) =>
                            AuraColors.brandGradient.createShader(b),
                        child: const Text('Create one',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gradient button ───────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback? onTap;
  const _GradientButton(
      {required this.loading, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? AuraColors.brandGradient
              : const LinearGradient(
                  colors: [Color(0xFF4A3880), Color(0xFF7A2A50)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: AuraColors.accent.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
      ),
    );
  }
}

// ── Tab chip ──────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? AuraColors.brandGradient : null,
            color: selected ? null : AuraColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AuraColors.divider,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                color: selected ? Colors.white : AuraColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.normal,
              )),
        ),
      );
}
