import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

class SongClipScreen extends StatefulWidget {
  final String toUsername;
  final String toDisplayName;

  const SongClipScreen({
    super.key,
    required this.toUsername,
    required this.toDisplayName,
  });

  @override
  State<SongClipScreen> createState() => _SongClipScreenState();
}

class _SongClipScreenState extends State<SongClipScreen> {
  // ── Search state ───────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selected;
  bool _searching = false;

  // ── Crop state ─────────────────────────────────────────────────
  // iTunes previews are 30 seconds; max clip = 15 seconds
  static const double _previewMax = 30.0;
  static const double _maxClip = 15.0;
  RangeValues _range = const RangeValues(0, 12);
  List<double> _wave = [];

  // ── Playback ───────────────────────────────────────────────────
  final _player = AudioPlayer();
  bool _playing = false;
  double _playPos = 0; // seconds into preview, for progress display
  Timer? _stopTimer;
  Timer? _posTimer;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _player.dispose();
    _stopTimer?.cancel();
    _posTimer?.cancel();
    super.dispose();
  }

  // ── Wave generator (deterministic per song title) ─────────────

  List<double> _makeWave(String seed) {
    final rng = math.Random(seed.hashCode.abs());
    return List.generate(48, (_) => 4.0 + rng.nextDouble() * 26.0);
  }

  // ── Search ─────────────────────────────────────────────────────

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() { _searching = true; _results = []; });
    try {
      final res = await http.get(Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(q)}&media=music&limit=8'));
      final data = jsonDecode(res.body);
      setState(() {
        _results = List<Map<String, dynamic>>.from(data['results'] ?? []);
        _searching = false;
      });
    } catch (_) {
      setState(() => _searching = false);
    }
  }

  void _selectSong(Map<String, dynamic> r) {
    setState(() {
      _selected = r;
      _results = [];
      _searchCtrl.clear();
      _wave = _makeWave(r['trackName'] ?? '');
      _range = const RangeValues(0, 12);
      _playPos = 0;
    });
  }

  // ── Playback of selected clip region ──────────────────────────

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
      _stopTimer?.cancel();
      _posTimer?.cancel();
      setState(() { _playing = false; _playPos = _range.start; });
      return;
    }

    final url = _selected?['previewUrl'] as String?;
    if (url == null) return;

    setState(() { _playing = true; _playPos = _range.start; });

    try {
      await _player.setUrl(url);
      await _player.seek(Duration(milliseconds: (_range.start * 1000).round()));
      await _player.play();

      final clipMs = ((_range.end - _range.start) * 1000).round();

      // Update progress every 100ms
      _posTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        setState(() {
          _playPos = (_player.position.inMilliseconds / 1000.0)
              .clamp(_range.start, _range.end);
        });
      });

      // Stop at end of clip
      _stopTimer = Timer(Duration(milliseconds: clipMs), () async {
        await _player.pause();
        _posTimer?.cancel();
        if (mounted) setState(() { _playing = false; _playPos = _range.start; });
      });
    } catch (_) {
      _posTimer?.cancel();
      if (mounted) setState(() => _playing = false);
    }
  }

  // ── Range change (enforce max 15s) ────────────────────────────

  void _onRangeChanged(RangeValues v) {
    // Stop playback on range change
    if (_playing) {
      _player.pause();
      _stopTimer?.cancel();
      _posTimer?.cancel();
      _playing = false;
    }

    double start = v.start;
    double end = v.end;
    final dur = end - start;

    if (dur > _maxClip) {
      // Clamp whichever handle moved
      if (start != _range.start) {
        start = end - _maxClip;
      } else {
        end = start + _maxClip;
      }
    }
    setState(() => _range = RangeValues(
        start.clamp(0, _previewMax - 1),
        end.clamp(1, _previewMax)));
  }

  // ── Send ───────────────────────────────────────────────────────

  void _send() {
    if (_selected == null) return;
    OrbitState().sendClip(
      widget.toUsername,
      song: _selected!['trackName'] ?? '',
      artist: _selected!['artistName'] ?? '',
      artUrl: _selected!['artworkUrl100'],
      previewUrl: _selected!['previewUrl'],
      clipStart: _range.start,
      clipEnd: _range.end,
    );
    Navigator.pop(context, true);
  }

  // ── Time formatting ───────────────────────────────────────────

  String _fmt(double secs) {
    final s = secs.round();
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('drop a clip',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('to ${widget.toDisplayName}',
              style: const TextStyle(
                  fontSize: 11,
                  color: AuraTheme.accent,
                  fontWeight: FontWeight.w600)),
        ]),
        actions: [
          if (_selected != null)
            TextButton(
              onPressed: _send,
              child: const Text('Send',
                  style: TextStyle(
                      color: AuraTheme.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                // ── Song search ──
                const _SectionLabel('search a song'),
                const SizedBox(height: 6),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Artist, song title...',
                    prefixIcon:
                        const Icon(Icons.search, color: AuraTheme.accent),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AuraTheme.accent),
                            ),
                          )
                        : null,
                  ),
                  onSubmitted: _search,
                  textInputAction: TextInputAction.search,
                ),
                const SizedBox(height: 8),

                // ── Results list ──
                if (_selected == null && _results.isNotEmpty)
                  ..._results.map(_resultTile),

                // ── Selected song + crop UI ──
                if (_selected != null) ...[
                  _selectedCard(),
                  const SizedBox(height: 20),
                  const _SectionLabel('pick your moment'),
                  const SizedBox(height: 4),
                  _waveformSection(),
                  const SizedBox(height: 12),
                  _playbackControl(),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'max ${_maxClip.round()} seconds  ·  drag the handles',
                      style: const TextStyle(
                          color: AuraTheme.textMuted, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _hintCard(),
                ],

                // ── Empty state ──
                if (_selected == null && _results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 52),
                    child: Center(
                      child: Column(children: [
                        Text('🎵', style: TextStyle(fontSize: 44)),
                        SizedBox(height: 10),
                        Text('find the song, crop the part that hits',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AuraTheme.textMuted, fontSize: 14)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),

          // ── Send button ──
          if (_selected != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuraTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'send clip to ${widget.toDisplayName} 🎵',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Result tile ────────────────────────────────────────────────

  Widget _resultTile(Map<String, dynamic> r) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          r['artworkUrl60'] ?? '',
          width: 46, height: 46, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 46, height: 46,
            color: AuraTheme.surface,
            child: const Icon(Icons.music_note, color: AuraTheme.accent),
          ),
        ),
      ),
      title: Text(r['trackName'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(r['artistName'] ?? '',
          style: const TextStyle(
              color: AuraTheme.textSecondary, fontSize: 12)),
      onTap: () => _selectSong(r),
    );
  }

  // ── Selected song card ─────────────────────────────────────────

  Widget _selectedCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AuraTheme.accent.withOpacity(0.3), width: 1.5),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            _selected!['artworkUrl100'] ?? '',
            width: 52, height: 52, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 52, height: 52,
              color: AuraTheme.surface,
              child: const Icon(Icons.music_note, color: AuraTheme.accent),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_selected!['trackName'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(_selected!['artistName'] ?? '',
                style: const TextStyle(
                    color: AuraTheme.textSecondary, fontSize: 12)),
          ]),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _selected = null;
            _wave = [];
            _playing = false;
            _stopTimer?.cancel();
            _posTimer?.cancel();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
                color: AuraTheme.surface,
                borderRadius: BorderRadius.circular(8)),
            child: const Text('change',
                style: TextStyle(
                    color: AuraTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  // ── Waveform + RangeSlider ─────────────────────────────────────

  Widget _waveformSection() {
    return Container(
      decoration: BoxDecoration(
          color: AuraTheme.card, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Column(children: [
        // ── Waveform bars ──
        SizedBox(
          height: 52,
          child: LayoutBuilder(builder: (ctx, box) {
            final barW = (box.maxWidth - (_wave.length - 1) * 2) / _wave.length;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _wave.asMap().entries.map((e) {
                // What time does this bar represent?
                final barTime = e.key / _wave.length * _previewMax;
                final inRange =
                    barTime >= _range.start && barTime <= _range.end;
                // Is the playhead past this bar?
                final played =
                    _playing && barTime >= _range.start && barTime <= _playPos;

                Color barColor;
                if (played) {
                  barColor = AuraTheme.accent;
                } else if (inRange) {
                  barColor = AuraTheme.accentLight;
                } else {
                  barColor = AuraTheme.surface;
                }

                return Container(
                  width: barW.clamp(2.0, 8.0),
                  height: e.value,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(2)),
                );
              }).toList(),
            );
          }),
        ),
        const SizedBox(height: 8),

        // ── RangeSlider ──
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AuraTheme.accent.withOpacity(0.3),
            inactiveTrackColor: Colors.transparent,
            thumbColor: AuraTheme.accent,
            overlayColor: AuraTheme.accent.withOpacity(0.12),
            trackHeight: 3,
            rangeThumbShape:
                const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
          ),
          child: RangeSlider(
            values: _range,
            min: 0,
            max: _previewMax,
            divisions: 300,
            onChanged: _onRangeChanged,
          ),
        ),

        // ── Time labels ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(_range.start),
                  style: const TextStyle(
                      fontSize: 11,
                      color: AuraTheme.accent,
                      fontWeight: FontWeight.w700)),
              Text(
                '${_fmt(_range.end - _range.start)} clip',
                style: const TextStyle(
                    fontSize: 11,
                    color: AuraTheme.textMuted,
                    fontWeight: FontWeight.w500),
              ),
              Text(_fmt(_range.end),
                  style: const TextStyle(
                      fontSize: 11,
                      color: AuraTheme.accent,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ── Playback control row ───────────────────────────────────────

  Widget _playbackControl() {
    final clipSecs = _range.end - _range.start;
    final progFrac =
        _playing ? ((_playPos - _range.start) / clipSecs).clamp(0.0, 1.0) : 0.0;

    return Row(children: [
      GestureDetector(
        onTap: _togglePlay,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
              color: AuraTheme.accent, shape: BoxShape.circle),
          child: Icon(
            _playing
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progFrac,
              backgroundColor: AuraTheme.surface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AuraTheme.accent),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _playing
                ? '${_fmt(_playPos - _range.start)} / ${_fmt(clipSecs)}'
                : 'preview your clip',
            style: const TextStyle(
                fontSize: 11, color: AuraTheme.textMuted),
          ),
        ]),
      ),
    ]);
  }

  // ── Hint card ─────────────────────────────────────────────────

  Widget _hintCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: AuraTheme.accent.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Text('💡', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'pick the part that hit you — the chorus drop, '
            'a lyric, the moment that made you think of '
            '${widget.toDisplayName}',
            style: const TextStyle(
                color: AuraTheme.textSecondary,
                fontSize: 12,
                height: 1.45),
          ),
        ),
      ]),
    );
  }
}

// ── Small helper ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AuraTheme.textMuted,
            letterSpacing: 0.8),
      );
}
