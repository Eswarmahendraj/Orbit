import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../theme/aura_theme.dart';
import '../onboarding/interests_screen.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String name;
  final String phone;
  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.name,
    required this.phone,
  });
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _auth = AuthService();
  bool _loading = false;

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) return;
    setState(() => _loading = true);
    try {
      await _auth.verifyOtp(
        verificationId: widget.verificationId,
        otp: _otp,
        name: widget.name,
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const InterestsScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid OTP. Try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your number')),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Enter the 6-digit code',
                style: Theme.of(context).textTheme.headlineMedium)
                .animate().fadeIn(),
            const SizedBox(height: 8),
            Text('Sent to ${widget.phone}',
                style: const TextStyle(
                    color: AuraColors.textSecondary, fontSize: 14))
                .animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 40),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _OtpBox(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                onChanged: (val) {
                  if (val.isNotEmpty && i < 5) {
                    _focusNodes[i + 1].requestFocus();
                  }
                  if (val.isEmpty && i > 0) {
                    _focusNodes[i - 1].requestFocus();
                  }
                  if (_otp.length == 6) _verify();
                },
              )),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Verify & Enter Orbit'),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Change number',
                    style: TextStyle(color: AuraColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 46,
    height: 56,
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      maxLength: 1,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: AuraColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuraColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuraColors.accent, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuraColors.divider),
        ),
      ),
    ),
  );
}
