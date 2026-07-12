import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  File? _pfp;
  bool _saving = false;

  static const _moods = [
    ('chill', '☀️'), ('hyped', '⚡'), ('nostalgic', '🌙'),
    ('focused', '🎧'), ('sad', '🌧️'), ('romantic', '💫'),
    ('cozy', '🫶'), ('euphoric', '✨'), ('hype', '🔥'), ('2am', '🌑'),
  ];

  @override
  void initState() {
    super.initState();
    final s = OrbitState();
    _nameCtrl = TextEditingController(text: s.displayName);
    _usernameCtrl = TextEditingController(
        text: s.username.startsWith('@') ? s.username.substring(1) : s.username);
    _bioCtrl = TextEditingController(text: s.bio);
    _pfp = s.pfpFile;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final f = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f != null) setState(() => _pfp = File(f.path));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final s = OrbitState();
    final name = _nameCtrl.text.trim();
    final raw = _usernameCtrl.text.trim();
    s.displayName = name.isEmpty ? s.displayName : name;
    s.username = raw.isEmpty
        ? s.username
        : (raw.startsWith('@') ? raw : '@$raw');
    s.bio = _bioCtrl.text.trim();
    if (_pfp != null) s.pfpFile = _pfp;
    await s.save();
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = OrbitState();
    final initial = state.displayName.isNotEmpty
        ? state.displayName[0].toUpperCase()
        : 'Y';

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: const Text('edit profile',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AuraTheme.accent)))
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(
                          color: AuraTheme.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PFP
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraTheme.surface,
                        border: Border.all(color: AuraTheme.accent, width: 2.5),
                        image: _pfp != null
                            ? DecorationImage(
                                image: FileImage(_pfp!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _pfp == null
                          ? Center(
                              child: Text(initial,
                                  style: const TextStyle(
                                      color: AuraTheme.accent,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800)))
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                            color: AuraTheme.accent, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('tap to change photo',
                  style: TextStyle(color: AuraTheme.textMuted, fontSize: 12)),
            ),
            const SizedBox(height: 28),

            // Fields
            _label('Display name'),
            const SizedBox(height: 6),
            _field(_nameCtrl, 'Your name', Icons.person_outline),
            const SizedBox(height: 16),

            _label('Username'),
            const SizedBox(height: 6),
            _field(_usernameCtrl, 'handle (without @)', Icons.alternate_email),
            const SizedBox(height: 16),

            _label('Bio'),
            const SizedBox(height: 6),
            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: "what's your vibe?",
                filled: true,
                fillColor: AuraTheme.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AuraTheme.accent)),
                counterStyle:
                    const TextStyle(color: AuraTheme.textMuted, fontSize: 11),
              ),
            ),
            const SizedBox(height: 24),

            // Mood picker
            _label('Current mood'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods.map((m) {
                final selected = state.mood == m.$1;
                return GestureDetector(
                  onTap: () {
                    state.mood = m.$1;
                    state.moodEmoji = m.$2;
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AuraTheme.accent : AuraTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(m.$2, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(m.$1,
                          style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AuraTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save changes',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AuraTheme.textPrimary));

  Widget _field(TextEditingController ctrl, String hint, IconData icon) =>
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AuraTheme.accent, size: 20),
          filled: true,
          fillColor: AuraTheme.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AuraTheme.accent)),
        ),
      );
}
