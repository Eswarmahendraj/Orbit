import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../theme/aura_theme.dart';
import 'otp_screen.dart';
import '../onboarding/interests_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _auth = AuthService();

  bool _usePhone = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
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
          onAutoVerified: (cred) async {
            await _auth.verifyOtp(
              verificationId: '',
              otp: '',
              name: _nameCtrl.text.trim(),
            );
          },
          onCodeSent: (verificationId, _) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => OtpScreen(
                verificationId: verificationId,
                name: _nameCtrl.text.trim(),
                phone: '+91${_phoneCtrl.text.trim()}',
              ),
            ));
          },
          onError: (e) {
            _showError(e.message ?? 'Error sending OTP');
          },
        );
      } else {
        await _auth.signUpWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
        );
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const InterestsScreen()),
            (_) => false,
          );
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Vybe logo
                Center(
                  child: Text(
                    'Vybe',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [AuraColors.accent, AuraColors.accentLight],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),

                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Be together without being available.',
                    style: TextStyle(color: AuraColors.textSecondary, fontSize: 13),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 48),

                Text('Create your account',
                    style: Theme.of(context).textTheme.headlineMedium)
                    .animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 6),
                const Text('Your Aura name will be generated automatically.',
                    style: TextStyle(color: AuraColors.textSecondary, fontSize: 13)),

                const SizedBox(height: 32),

                // Name field
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline, color: AuraColors.textSecondary),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your name' : null,
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 16),

                // Toggle email / phone
                Row(
                  children: [
                    _ToggleChip(
                      label: 'Email',
                      selected: !_usePhone,
                      onTap: () => setState(() => _usePhone = false),
                    ),
                    const SizedBox(width: 10),
                    _ToggleChip(
                      label: 'Mobile',
                      selected: _usePhone,
                      onTap: () => setState(() => _usePhone = true),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 16),

                if (!_usePhone) ...[
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.mail_outline, color: AuraColors.textSecondary),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter a valid email' : null,
                  ).animate().fadeIn(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AuraColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AuraColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => v == null || v.length < 6
                        ? 'Minimum 6 characters' : null,
                  ).animate().fadeIn(),
                ] else ...[
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixIcon: Icon(Icons.phone_outlined,
                          color: AuraColors.textSecondary),
                      prefixText: '+91  ',
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (v) => v == null || v.length != 10
                        ? 'Enter a valid 10-digit number' : null,
                  ).animate().fadeIn(),
                ],

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_usePhone ? 'Send OTP' : 'Create Account'),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ',
                        style: TextStyle(color: AuraColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Sign in',
                          style: TextStyle(
                              color: AuraColors.accent,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AuraColors.accent : AuraColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? AuraColors.accent : AuraColors.divider,
        ),
      ),
      child: Text(label,
          style: TextStyle(
            color: selected ? Colors.white : AuraColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          )),
    ),
  );
}
