import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrbitQRScreen — scan-to-add via QR code
// ─────────────────────────────────────────────────────────────────────────────

class OrbitQRScreen extends StatefulWidget {
  const OrbitQRScreen({super.key});
  @override
  State<OrbitQRScreen> createState() => _OrbitQRScreenState();
}

class _OrbitQRScreenState extends State<OrbitQRScreen>
    with SingleTickerProviderStateMixin {
  final _state = OrbitState();
  bool _scanning = false;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  String get _qrData => 'orbit://add/${_state.username}';

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _qrData));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Link copied to clipboard 🔗'),
      backgroundColor: AuraTheme.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Sharing ${_state.username}\'s Orbit QR code...'),
      backgroundColor: AuraTheme.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _startScan() {
    setState(() => _scanning = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScanSheet(
        onScanned: (handle) {
          if (mounted) {
            setState(() => _scanning = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Added $handle to your Orbit! 🎉'),
              backgroundColor: AuraTheme.accent,
              behavior: SnackBarBehavior.floating,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _scanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = _state.username;
    final displayName = _state.displayName;

    return Scaffold(
      backgroundColor: AuraTheme.themeBg,
      appBar: AppBar(
        backgroundColor: AuraTheme.themeBg,
        title: Text('orbit QR',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AuraTheme.themeTextPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AuraTheme.themeTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Card ─────────────────────────────────────────────
              AnimatedBuilder(
                animation: _shimmer,
                builder: (_, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          AuraTheme.themeSurface,
                          AuraTheme.themeCard,
                          AuraTheme.themeSurface,
                        ],
                        stops: [
                          (_shimmer.value - 0.4).clamp(0.0, 1.0),
                          _shimmer.value.clamp(0.0, 1.0),
                          (_shimmer.value + 0.4).clamp(0.0, 1.0),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AuraTheme.accent.withOpacity(0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(children: [
                    // Brand header
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AuraTheme.accent,
                                  AuraTheme.accentLight
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.wifi_tethering_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text('ORBIT',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 2,
                                  color: AuraTheme.themeTextPrimary)),
                        ]),
                    const SizedBox(height: 24),

                    // QR code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AuraTheme.accent.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1A1A1A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // User info
                    Text(displayName,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: AuraTheme.themeTextPrimary)),
                    const SizedBox(height: 4),
                    Text(username,
                        style: TextStyle(
                            color: AuraTheme.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AuraTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('scan to sync on orbit 🔄',
                          style: TextStyle(
                              color: AuraTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 32),

              // ── Action buttons ────────────────────────────────────
              Row(children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: _share,
                    primary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.link_rounded,
                    label: 'Copy link',
                    onTap: _copyLink,
                    primary: false,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              // Scan button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _startScan,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AuraTheme.accent.withOpacity(0.5)),
                    foregroundColor: AuraTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan a friend\'s QR code',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),

              const SizedBox(height: 24),

              // ── Tip ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AuraTheme.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AuraTheme.accent.withOpacity(0.2))),
                child: Row(children: [
                  const Text('💡',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Point your friend\'s camera at this QR code to instantly sync up on Orbit.',
                      style: TextStyle(
                          fontSize: 13,
                          color: AuraTheme.themeTextSecondary,
                          height: 1.4),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.primary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: primary ? AuraTheme.accent : AuraTheme.themeCard,
          borderRadius: BorderRadius.circular(16),
          border: primary
              ? null
              : Border.all(
                  color: AuraTheme.accent.withOpacity(0.3)),
          boxShadow: primary
              ? [
                  BoxShadow(
                      color: AuraTheme.accent.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              color: primary ? Colors.white : AuraTheme.accent,
              size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: primary ? Colors.white : AuraTheme.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ScanSheet — type a handle manually (camera scan is device-native)
// ─────────────────────────────────────────────────────────────────────────────

class _ScanSheet extends StatefulWidget {
  final ValueChanged<String> onScanned;
  const _ScanSheet({required this.onScanned});

  @override
  State<_ScanSheet> createState() => _ScanSheetState();
}

class _ScanSheetState extends State<_ScanSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AuraTheme.themeCard,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AuraTheme.themeTextMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Scan viewfinder (decorative)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AuraTheme.accent.withOpacity(0.5), width: 2),
            ),
            child: Stack(children: [
              // Corner markers
              ...[ Alignment.topLeft, Alignment.topRight,
                   Alignment.bottomLeft, Alignment.bottomRight]
                  .map((a) => Align(
                        alignment: a,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border(
                              top: a.y < 0
                                  ? BorderSide(
                                      color: AuraTheme.accent,
                                      width: 3)
                                  : BorderSide.none,
                              bottom: a.y > 0
                                  ? BorderSide(
                                      color: AuraTheme.accent,
                                      width: 3)
                                  : BorderSide.none,
                              left: a.x < 0
                                  ? BorderSide(
                                      color: AuraTheme.accent,
                                      width: 3)
                                  : BorderSide.none,
                              right: a.x > 0
                                  ? BorderSide(
                                      color: AuraTheme.accent,
                                      width: 3)
                                  : BorderSide.none,
                            ),
                          ),
                        ),
                      )),
              const Center(
                child: Text('📷',
                    style: TextStyle(fontSize: 48)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Point camera at friend\'s Orbit QR',
              style: TextStyle(
                  color: AuraTheme.themeTextSecondary,
                  fontSize: 13)),
          const SizedBox(height: 20),

          // Manual entry fallback
          Text('— or type their username —',
              style: TextStyle(
                  color: AuraTheme.themeTextMuted, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: '@username',
              filled: true,
              fillColor: AuraTheme.themeSurface,
              prefixIcon: const Icon(Icons.alternate_email_rounded,
                  color: AuraTheme.accent),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
            textInputAction: TextInputAction.go,
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) {
                final handle =
                    v.trim().startsWith('@') ? v.trim() : '@${v.trim()}';
                widget.onScanned(handle);
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 14),
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
              onPressed: () {
                final v = _ctrl.text.trim();
                if (v.isNotEmpty) {
                  final handle = v.startsWith('@') ? v : '@$v';
                  widget.onScanned(handle);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add to Orbit',
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
