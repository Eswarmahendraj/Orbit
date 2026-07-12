import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _step = 0;

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  File? _pfp;
  String _mood = 'chill';
  String _moodEmoji = '☀️';

  static const _moods = [
    ('chill', '☀️'),
    ('hype', '🔥'),
    ('cozy', '🫶'),
    ('2am', '🌙'),
    ('focused', '🎧'),
    ('heartbreak', '💔'),
    ('euphoric', '✨'),
    ('nostalgia', '🎞️'),
  ];

  @override
  void dispose() {
    _pages.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      _pages.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _pickPhoto() async {
    final f = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f != null) setState(() => _pfp = File(f.path));
  }

  void _finish() {
    final state = OrbitState();
    final name = _nameCtrl.text.trim();
    state.displayName = name.isEmpty ? 'You' : name;
    final raw = _usernameCtrl.text.trim();
    state.username = raw.isEmpty
        ? '@you'
        : (raw.startsWith('@') ? raw : '@$raw');
    state.bio = _bioCtrl.text.trim();
    if (_pfp != null) state.pfpFile = _pfp;
    state.mood = _mood;
    state.moodEmoji = _moodEmoji;
    state.hasOnboarded = true;
    state.save();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _step == i ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _step == i
                        ? AuraTheme.accent
                        : AuraTheme.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          const Text('🌌', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text('Welcome to Orbit',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AuraTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Set up your identity to get started',
              style:
                  TextStyle(fontSize: 15, color: AuraTheme.textSecondary)),
          const SizedBox(height: 36),
          _field(_nameCtrl, 'Display name', 'e.g. Eswar'),
          const SizedBox(height: 14),
          _field(_usernameCtrl, 'Username', 'e.g. eswar.m  (@ added automatically)'),
          const SizedBox(height: 14),
          _field(_bioCtrl, 'Bio (optional)', "what's your vibe?", maxLines: 2),
          const Spacer(),
          _nextBtn('Continue →'),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          const Text('📸', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text('Your profile photo',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AuraTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Show your orbit who you are',
              style:
                  TextStyle(fontSize: 15, color: AuraTheme.textSecondary)),
          const SizedBox(height: 48),
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuraTheme.surface,
                  border: Border.all(color: AuraTheme.accent, width: 3),
                  image: _pfp != null
                      ? DecorationImage(
                          image: FileImage(_pfp!), fit: BoxFit.cover)
                      : null,
                ),
                child: _pfp == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: AuraTheme.accent, size: 34),
                          SizedBox(height: 6),
                          Text('Add photo',
                              style: TextStyle(
                                  color: AuraTheme.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_library_outlined,
                  color: AuraTheme.accent, size: 18),
              label: const Text('Choose from gallery',
                  style: TextStyle(color: AuraTheme.accent)),
            ),
          ),
          const Spacer(),
          _nextBtn('Continue →'),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _next,
              child: const Text('Skip for now',
                  style: TextStyle(color: AuraTheme.textMuted, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          const Text('🎵', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text("What's your vibe?",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AuraTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Pick your current mood',
              style:
                  TextStyle(fontSize: 15, color: AuraTheme.textSecondary)),
          const SizedBox(height: 28),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: _moods.map((m) {
                final selected = _mood == m.$1;
                return GestureDetector(
                  onTap: () =>
                      setState(() {
                        _mood = m.$1;
                        _moodEmoji = m.$2;
                      }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected ? AuraTheme.accent : AuraTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AuraTheme.accent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(m.$2, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(m.$1,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AuraTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _nextBtn('Enter Orbit 🚀'),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AuraTheme.accent, fontSize: 13),
        filled: true,
        fillColor: AuraTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AuraTheme.accent),
        ),
      ),
    );
  }

  Widget _nextBtn(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuraTheme.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
