import 'package:flutter/material.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

class CreateCampfireScreen extends StatefulWidget {
  const CreateCampfireScreen({super.key});

  @override
  State<CreateCampfireScreen> createState() => _CreateCampfireScreenState();
}

class _CreateCampfireScreenState extends State<CreateCampfireScreen> {
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _pinEnabled = false;
  Set<String> _invited = {};

  static const _friends = [
    ('@maya.k', 'maya', 'M', Color(0xFFFF8C42)),
    ('@zara.w', 'zara', 'Z', Color(0xFF6C63FF)),
    ('@dev.s', 'dev', 'D', Color(0xFFFF7A50)),
    ('@rina.p', 'rina', 'R', Color(0xFF00B894)),
    ('@jay.r', 'jay', 'J', Color(0xFFE17055)),
  ];

  static const _emojis = ['🔥', '🌙', '☀️', '🎧', '⚡', '🎓', '🤫', '💫', '🎵', '🌊'];
  String _selectedEmoji = '🔥';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _create() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your campfire a name')),
      );
      return;
    }
    OrbitState().addCampfire({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameCtrl.text.trim(),
      'emoji': _selectedEmoji,
      'pin': _pinEnabled && _pinCtrl.text.length == 4 ? _pinCtrl.text : null,
      'members': _invited.toList(),
      'created': DateTime.now().toIso8601String(),
      'messages': [],
      'isLive': true,
    });
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: const Text('new campfire 🔥',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: _create,
            child: const Text('Create',
                style: TextStyle(
                    color: AuraTheme.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Name
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'Campfire name...',
              prefixIcon: Icon(Icons.local_fire_department_outlined,
                  color: AuraTheme.accent),
            ),
          ),
          const SizedBox(height: 24),

          // Emoji picker
          const Text('Pick an emoji',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              itemBuilder: (_, i) {
                final sel = _selectedEmoji == _emojis[i];
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = _emojis[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: sel ? AuraTheme.accent : AuraTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(_emojis[i],
                          style: TextStyle(fontSize: sel ? 26 : 22)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Invite friends
          const Text('Invite to campfire',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          ..._friends.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: AuraTheme.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CheckboxListTile(
                  value: _invited.contains(f.$1),
                  onChanged: (v) => setState(
                      () => v! ? _invited.add(f.$1) : _invited.remove(f.$1)),
                  title: Row(children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: f.$4.withOpacity(0.15),
                      child: Text(f.$3,
                          style: TextStyle(
                              color: f.$4, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.$2,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(f.$1,
                          style: const TextStyle(
                              color: AuraTheme.textSecondary, fontSize: 12)),
                    ]),
                  ]),
                  activeColor: AuraTheme.accent,
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              )),
          const SizedBox(height: 16),

          // PIN toggle
          Container(
            decoration: BoxDecoration(
                color: AuraTheme.card, borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
              title: const Text('PIN protection',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Members need a PIN to enter',
                  style:
                      TextStyle(color: AuraTheme.textSecondary, fontSize: 12)),
              value: _pinEnabled,
              onChanged: (v) => setState(() => _pinEnabled = v),
              activeColor: AuraTheme.accent,
            ),
          ),
          if (_pinEnabled) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Set 4-digit PIN',
                prefixIcon: Icon(Icons.lock_outline, color: AuraTheme.accent),
                counterText: '',
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Light the campfire 🔥',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
