import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

class CreateVybeScreen extends StatefulWidget {
  const CreateVybeScreen({super.key});

  @override
  State<CreateVybeScreen> createState() => _CreateVybeScreenState();
}

class _CreateVybeScreenState extends State<CreateVybeScreen> {
  final _searchCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();

  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selected;
  File? _photo;
  String _tag = '#chill';
  bool _searching = false;
  // 24h is now the DEFAULT — always on, user can opt out
  bool _disappearing = true;
  Timer? _debounce;

  // Song crop
  double _clipStart = 0.0;
  double _clipEnd = 15.0; // seconds (iTunes preview is 30s max)

  // Hashtag support
  List<String> _hashtagSuggestions = [];
  bool _showHashtagSuggestions = false;

  static const _tags = [
    '#chill', '#hype', '#heartbreak', '#2am',
    '#nostalgia', '#focused', '#euphoric', '#cozy',
  ];

  static const _allHashtags = [
    '#chill', '#hype', '#heartbreak', '#2am', '#nostalgia',
    '#focused', '#euphoric', '#cozy', '#vibing', '#latenight',
    '#sadsongs', '#mainfits', '#aesthetic', '#darkacademia',
    '#dreamy', '#romanticera', '#goodvibes', '#trendingsong',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _captionCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(q));
  }

  void _onCaptionChanged(String text) {
    // Detect hashtag typing — show suggestions
    final words = text.split(' ');
    final last = words.isNotEmpty ? words.last : '';
    if (last.startsWith('#') && last.length > 1) {
      final query = last.toLowerCase();
      final matches = _allHashtags
          .where((h) => h.toLowerCase().startsWith(query))
          .take(6)
          .toList();
      setState(() {
        _hashtagSuggestions = matches;
        _showHashtagSuggestions = matches.isNotEmpty;
      });
    } else {
      setState(() => _showHashtagSuggestions = false);
    }
  }

  void _insertHashtag(String tag) {
    final text = _captionCtrl.text;
    final words = text.split(' ');
    words[words.length - 1] = tag;
    final updated = '${words.join(' ')} ';
    _captionCtrl.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );
    setState(() => _showHashtagSuggestions = false);
  }

  // ── Photo picker ───────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AuraTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AuraTheme.accent,
              child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
            title: const Text('take a photo',
                style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AuraTheme.surface,
              child: Icon(Icons.photo_library_rounded,
                  color: AuraTheme.accent, size: 20),
            ),
            title: const Text('choose from gallery',
                style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (choice == null) return;
    final xfile = await _picker.pickImage(
        source: choice, imageQuality: 85, maxWidth: 1080);
    if (xfile != null && mounted) {
      setState(() => _photo = File(xfile.path));
    }
  }

  // ── Song search ────────────────────────────────────────────────

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() { _searching = true; _results = []; });
    try {
      final res = await http.get(Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(q)}&media=music&limit=10'));
      final data = jsonDecode(res.body);
      setState(() {
        _results = List<Map<String, dynamic>>.from(data['results'] ?? []);
        _searching = false;
      });
    } catch (_) {
      setState(() => _searching = false);
    }
  }

  // ── Song crop sheet ────────────────────────────────────────────

  void _showCropSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _SongCropSheet(
        songTitle: _selected!['trackName'] ?? '',
        start: _clipStart,
        end: _clipEnd,
        onChanged: (s, e) {
          setState(() {
            _clipStart = s;
            _clipEnd = e;
          });
        },
      ),
    );
  }

  // ── Post ───────────────────────────────────────────────────────

  void _post() {
    if (_selected == null) return;
    final state = OrbitState();
    state.addPost({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user': state.displayName,
      'username': state.username,
      'song': _selected!['trackName'] ?? '',
      'artist': _selected!['artistName'] ?? '',
      'art': _selected!['artworkUrl100'] ?? '',
      'preview': _selected!['previewUrl'] ?? '',
      'tag': _tag,
      'caption': _captionCtrl.text.trim(),
      'disappearing': _disappearing,
      'photo': _photo?.path,
      'time': DateTime.now().toIso8601String(),
      'fires': 0,
    });
    Navigator.pop(context, true);
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        title: const Text('drop a vybe 🎵',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (_selected != null)
            TextButton(
              onPressed: _post,
              child: const Text('Post',
                  style: TextStyle(
                      color: AuraTheme.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [

                // ── Photo section ──
                _photoSection(),
                const SizedBox(height: 14),

                // ── Song search ──
                const Text('SONG',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AuraTheme.textMuted,
                        letterSpacing: 0.8)),
                const SizedBox(height: 6),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search a song...',
                    prefixIcon: const Icon(Icons.search, color: AuraTheme.accent),
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
                  onChanged: _onSearchChanged,
                  onSubmitted: _search,
                  textInputAction: TextInputAction.search,
                ),
                const SizedBox(height: 8),

                // ── Search results (before selection) ──
                if (_selected == null && _results.isNotEmpty)
                  ..._results.map((r) => _resultTile(r)),

                // ── Selected song card ──
                if (_selected != null) ...[
                  _selectedCard(),
                  const SizedBox(height: 14),

                  // Caption with hashtag suggestions
                  TextField(
                    controller: _captionCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Add a caption... type # for hashtags'),
                    maxLines: 2,
                    onChanged: _onCaptionChanged,
                  ),
                  if (_showHashtagSuggestions) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _hashtagSuggestions.map((tag) =>
                          GestureDetector(
                            onTap: () => _insertHashtag(tag),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AuraTheme.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AuraTheme.accent.withOpacity(0.3)),
                              ),
                              child: Text(tag, style: const TextStyle(
                                color: AuraTheme.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                            ),
                          )
                        ).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Mood tags
                  const Text('VIBE TAG',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AuraTheme.textMuted,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((t) {
                      final sel = _tag == t;
                      return GestureDetector(
                        onTap: () => setState(() => _tag = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AuraTheme.accent : AuraTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : AuraTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 24h toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: AuraTheme.card,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.timer_outlined,
                          color: AuraTheme.accent, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Disappears in 24h',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('your vybe will vanish after 24 hours',
                              style: TextStyle(
                                  color: AuraTheme.textMuted, fontSize: 11)),
                        ]),
                      ),
                      Switch(
                        value: _disappearing,
                        onChanged: (v) => setState(() => _disappearing = v),
                        activeColor: AuraTheme.accent,
                      ),
                    ]),
                  ),
                ],

                // ── Empty state ──
                if (_selected == null && _results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: Column(children: [
                        const Text('🎵', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text('Search for a song to share',
                            style: TextStyle(
                                color: AuraTheme.textMuted, fontSize: 15)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),

          // ── Bottom post button ──
          if (_selected != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _post,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuraTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('drop it 🔥',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Photo section widget ───────────────────────────────────────

  Widget _photoSection() {
    if (_photo != null) {
      // show preview with remove button
      return Stack(clipBehavior: Clip.none, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _photo!,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _photo = null),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
        // Edit button
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                SizedBox(width: 5),
                Text('change',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ]);
    }

    // Empty picker
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: AuraTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AuraTheme.textMuted.withOpacity(0.25),
              width: 1.5,
              style: BorderStyle.solid),
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          const Icon(Icons.add_photo_alternate_outlined,
              color: AuraTheme.accent, size: 32),
          const SizedBox(height: 7),
          const Text('add a photo',
              style: TextStyle(
                  color: AuraTheme.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const SizedBox(height: 2),
          Text('optional — song is the star ✨',
              style: TextStyle(
                  color: AuraTheme.textMuted.withOpacity(0.7),
                  fontSize: 11)),
        ]),
      ),
    );
  }

  // ── Song result tile ───────────────────────────────────────────

  Widget _resultTile(Map<String, dynamic> r) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          r['artworkUrl60'] ?? '',
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 46,
            height: 46,
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
      onTap: () => setState(() {
        _selected = r;
        _results = [];
        _searchCtrl.clear();
      }),
    );
  }

  // ── Selected song card ─────────────────────────────────────────

  Widget _selectedCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraTheme.accent.withOpacity(0.3), width: 1.5),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            _selected!['artworkUrl100'] ?? '',
            width: 54,
            height: 54,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 54,
              height: 54,
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
        // Crop + Change column
        Column(children: [
          // Crop button
          GestureDetector(
            onTap: _showCropSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                  color: AuraTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.content_cut_rounded,
                    color: AuraTheme.accent, size: 11),
                const SizedBox(width: 3),
                const Text('crop',
                    style: TextStyle(
                        color: AuraTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          const SizedBox(height: 5),
          // Change song
          GestureDetector(
            onTap: () => setState(() {
              _selected = null;
              _searchCtrl.text = '';
              _clipStart = 0;
              _clipEnd = 15;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 5),
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
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SongCropSheet — waveform RangeSlider for cropping a song preview
// ─────────────────────────────────────────────────────────────────────────────

class _SongCropSheet extends StatefulWidget {
  final String songTitle;
  final double start;
  final double end;
  final void Function(double start, double end) onChanged;

  const _SongCropSheet({
    required this.songTitle,
    required this.start,
    required this.end,
    required this.onChanged,
  });

  @override
  State<_SongCropSheet> createState() => _SongCropSheetState();
}

class _SongCropSheetState extends State<_SongCropSheet> {
  static const _maxPreview = 30.0; // iTunes preview length
  static const _maxClip = 15.0;
  late RangeValues _range;
  late List<double> _wave;

  @override
  void initState() {
    super.initState();
    _range = RangeValues(widget.start, widget.end);
    // Deterministic waveform from song title
    final rng = math.Random(widget.songTitle.hashCode.abs());
    _wave = List.generate(48, (_) => 4.0 + rng.nextDouble() * 26.0);
  }

  String _fmtSecs(double s) {
    final min = (s ~/ 60).toString();
    final sec = (s.toInt() % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final clipLen = _range.end - _range.start;
    final tooLong = clipLen > _maxClip;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AuraTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          Row(children: [
            const Icon(Icons.content_cut_rounded,
                color: AuraTheme.accent, size: 18),
            const SizedBox(width: 8),
            const Text('crop song clip',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('max ${_maxClip.toInt()}s',
                style: const TextStyle(
                    color: AuraTheme.textMuted, fontSize: 12)),
          ]),
          const SizedBox(height: 20),

          // Waveform visualizer
          SizedBox(
            height: 56,
            child: CustomPaint(
              size: const Size(double.infinity, 56),
              painter: _WaveformPainter(
                wave: _wave,
                startFrac: _range.start / _maxPreview,
                endFrac: _range.end / _maxPreview,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Range slider
          RangeSlider(
            values: _range,
            min: 0,
            max: _maxPreview,
            divisions: 120,
            activeColor: tooLong ? Colors.redAccent : AuraTheme.accent,
            inactiveColor: AuraTheme.surface,
            onChanged: (v) {
              if (v.end - v.start <= _maxClip) {
                setState(() => _range = v);
              } else {
                // Clamp: keep start, push end
                setState(() => _range =
                    RangeValues(v.start, v.start + _maxClip));
              }
            },
          ),

          // Time labels
          Row(children: [
            Text(_fmtSecs(_range.start),
                style: const TextStyle(
                    color: AuraTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${_fmtSecs(_range.end)}  (${clipLen.toStringAsFixed(0)}s)',
              style: TextStyle(
                  color: tooLong ? Colors.redAccent : AuraTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ]),

          if (tooLong)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Max clip is 15 seconds',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: tooLong
                  ? null
                  : () {
                      widget.onChanged(_range.start, _range.end);
                      Navigator.pop(context);
                    },
              child: const Text('Save crop',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> wave;
  final double startFrac;
  final double endFrac;
  const _WaveformPainter(
      {required this.wave,
      required this.startFrac,
      required this.endFrac});

  @override
  void paint(Canvas canvas, Size size) {
    final barW = size.width / wave.length;
    final midY = size.height / 2;
    for (int i = 0; i < wave.length; i++) {
      final x = i * barW + barW / 2;
      final h = wave[i];
      final frac = i / wave.length;
      final inRange = frac >= startFrac && frac <= endFrac;
      final paint = Paint()
        ..color = inRange
            ? AuraTheme.accent
            : AuraTheme.textMuted.withOpacity(0.3)
        ..strokeWidth = barW * 0.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(x, midY - h / 2), Offset(x, midY + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.startFrac != startFrac || old.endFrac != endFrac;
}
