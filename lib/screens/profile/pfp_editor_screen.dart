import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

class PfpEditorScreen extends StatefulWidget {
  const PfpEditorScreen({super.key});
  @override
  State<PfpEditorScreen> createState() => _PfpEditorScreenState();
}

class _PfpEditorScreenState extends State<PfpEditorScreen> {
  final _state = OrbitState();
  File? _file;
  String _filterId = 'none';

  static const _filters = [
    _Flt('none', 'Normal', null),
    _Flt('warm', 'Warm', [
      1.2, 0, 0, 0, 20,
      0, 1.0, 0, 0, 5,
      0, 0, 0.7, 0, -15,
      0, 0, 0, 1, 0,
    ]),
    _Flt('cool', 'Cool', [
      0.8, 0, 0, 0, -10,
      0, 1.0, 0, 0, 5,
      0, 0, 1.3, 0, 25,
      0, 0, 0, 1, 0,
    ]),
    _Flt('noir', 'Noir', [
      0.33, 0.33, 0.33, 0, 0,
      0.33, 0.33, 0.33, 0, 0,
      0.33, 0.33, 0.33, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    _Flt('rose', 'Rose', [
      1.2, 0.1, 0, 0, 15,
      0, 0.85, 0, 0, -5,
      0, 0, 0.85, 0, -5,
      0, 0, 0, 1, 0,
    ]),
    _Flt('golden', 'Golden', [
      1.3, 0.1, 0, 0, 25,
      0.1, 1.1, 0, 0, 10,
      0, 0, 0.55, 0, -20,
      0, 0, 0, 1, 0,
    ]),
    _Flt('fade', 'Fade', [
      0.85, 0, 0, 0, 40,
      0, 0.85, 0, 0, 35,
      0, 0, 0.85, 0, 30,
      0, 0, 0, 0.85, 0,
    ]),
    _Flt('vivid', 'Vivid', [
      1.5, -0.2, -0.2, 0, 0,
      -0.2, 1.5, -0.2, 0, 0,
      -0.2, -0.2, 1.5, 0, 0,
      0, 0, 0, 1, 0,
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _file = _state.pfpFile;
    _filterId = _state.pfpFilter;
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final xf = await ImagePicker().pickImage(
          source: source, imageQuality: 85, maxWidth: 800);
      if (xf != null) setState(() => _file = File(xf.path));
    } catch (_) {}
  }

  Widget _preview(double size) {
    final flt = _filters.firstWhere((f) => f.id == _filterId);
    Widget img;
    if (_file != null) {
      img = Image.file(_file!, fit: BoxFit.cover,
          width: size, height: size);
    } else {
      img = Container(
        width: size,
        height: size,
        color: AuraTheme.accent.withOpacity(0.18),
        child: Icon(Icons.person_rounded,
            size: size * 0.5, color: AuraTheme.accent),
      );
    }
    if (flt.matrix != null) {
      img = ColorFiltered(
          colorFilter: ColorFilter.matrix(flt.matrix!), child: img);
    }
    return ClipOval(child: SizedBox(width: size, height: size, child: img));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: const Text('edit photo',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context, false)),
        actions: [
          TextButton(
            onPressed: () async {
              _state.pfpFile = _file;
              _state.pfpFilter = _filterId;
              await _state.save();
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('save',
                style: TextStyle(
                    color: AuraTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 28),
          Center(child: _preview(180)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _srcBtn(Icons.camera_alt_rounded, 'Camera',
                  () => _pick(ImageSource.camera)),
              const SizedBox(width: 14),
              _srcBtn(Icons.photo_library_rounded, 'Gallery',
                  () => _pick(ImageSource.gallery)),
            ],
          ),
          const SizedBox(height: 28),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 20, bottom: 12),
              child: Text('filters',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          SizedBox(
            height: 106,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final sel = _filterId == f.id;
                return GestureDetector(
                  onTap: () => setState(() => _filterId = f.id),
                  child: Column(children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: sel
                                ? AuraTheme.accent
                                : Colors.transparent,
                            width: 2.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: _thumb(f),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(f.name,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? AuraTheme.accent
                                : AuraTheme.textMuted)),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(_Flt f) {
    Widget inner;
    if (_file != null) {
      inner = Image.file(_file!, fit: BoxFit.cover, width: 66, height: 66);
    } else {
      inner = Container(
        width: 66,
        height: 66,
        color: AuraTheme.accent.withOpacity(0.18),
        child: const Icon(Icons.person_rounded, color: AuraTheme.accent, size: 28),
      );
    }
    if (f.matrix != null) {
      return ColorFiltered(
          colorFilter: ColorFilter.matrix(f.matrix!), child: inner);
    }
    return inner;
  }

  Widget _srcBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: AuraTheme.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(icon, color: AuraTheme.accent, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      );
}

class _Flt {
  final String id;
  final String name;
  final List<double>? matrix;
  const _Flt(this.id, this.name, this.matrix);
}
