import 'package:flutter/material.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

class SecretVaultScreen extends StatefulWidget {
  const SecretVaultScreen({super.key});
  @override
  State<SecretVaultScreen> createState() => _SecretVaultScreenState();
}

class _SecretVaultScreenState extends State<SecretVaultScreen> {
  final _s = OrbitState();
  bool _unlocked = false;
  String _pin = '';
  String _err = '';

  final _items = [
    {'emoji': '🌙', 'label': 'late night thoughts', 'time': '2:14 AM', 'song': 'heather — conan gray'},
    {'emoji': '💭', 'label': 'that song i found today', 'time': 'yesterday', 'song': 'softly — keshi'},
    {'emoji': '🔥', 'label': 'mood board ideas', 'time': '3 days ago', 'song': null},
    {'emoji': '🌧️', 'label': 'rainy day thoughts', 'time': 'last week', 'song': 'the night we met — lord huron'},
  ];

  void _tryUnlock() {
    final code = _s.dmPasscode;
    if (code == null || _pin == code) {
      setState(() { _unlocked = true; _err = ''; });
    } else {
      setState(() { _err = 'wrong PIN'; _pin = ''; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: const Text('secret vault',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _unlocked ? _content() : _pinGate(),
    );
  }

  // ── PIN gate ─────────────────────────────────────────────

  Widget _pinGate() => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(children: [
            const SizedBox(height: 48),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: AuraTheme.accent, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('secret vault',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('only you can see what\'s in here',
                style: TextStyle(color: AuraTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 36),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? AuraTheme.accent : AuraTheme.surface,
                  border: Border.all(color: AuraTheme.accent.withOpacity(0.4)),
                ),
              )),
            ),
            const SizedBox(height: 10),
            AnimatedOpacity(
              opacity: _err.isNotEmpty ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(_err,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
            const SizedBox(height: 20),
            _numpad(),
            if (_s.dmPasscode == null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _unlocked = true),
                child: const Text('no PIN set — enter vault',
                    style: TextStyle(color: AuraTheme.textMuted)),
              ),
            ],
          ]),
        ),
      );

  Widget _numpad() {
    final keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.0,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        return GestureDetector(
          onTap: () {
            setState(() {
              _err = '';
              if (k == '⌫') {
                if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
              } else if (_pin.length < 4) {
                _pin += k;
                if (_pin.length == 4) _tryUnlock();
              }
            });
          },
          child: Center(
            child: Text(k,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w300)),
          ),
        );
      }).toList(),
    );
  }

  // ── Vault content ─────────────────────────────────────────

  Widget _content() => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(children: [
                Icon(Icons.lock_rounded, size: 13, color: AuraTheme.accent),
                SizedBox(width: 5),
                Text('only you can see this',
                    style: TextStyle(
                        color: AuraTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length + 1,
            itemBuilder: (_, i) {
              if (i == _items.length) {
                return GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add a private vybe to your vault'),
                      backgroundColor: AuraTheme.accent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AuraTheme.accent.withOpacity(0.25),
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: AuraTheme.accent),
                        SizedBox(width: 8),
                        Text('add private vybe',
                            style: TextStyle(
                                color: AuraTheme.accent,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }
              final item = _items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AuraTheme.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Text(item['emoji'] as String,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['label'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        if (item['song'] != null) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.music_note,
                                size: 12, color: AuraTheme.accent),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(item['song'] as String,
                                  style: const TextStyle(
                                      color: AuraTheme.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        ],
                        const SizedBox(height: 3),
                        Text(item['time'] as String,
                            style: const TextStyle(
                                color: AuraTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz, color: AuraTheme.textMuted),
                ]),
              );
            },
          ),
        ),
      ]);
}
