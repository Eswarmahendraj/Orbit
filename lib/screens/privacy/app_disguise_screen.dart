import 'dart:async';
import 'package:flutter/material.dart';
import '../home/home_screen.dart';

/// Fake iOS-style calculator. Long-press "=" for 3s → unlocks Orbit.
class AppDisguiseScreen extends StatefulWidget {
  const AppDisguiseScreen({super.key});
  @override
  State<AppDisguiseScreen> createState() => _AppDisguiseScreenState();
}

class _AppDisguiseScreenState extends State<AppDisguiseScreen> {
  String _display = '0';
  Timer? _longPressTimer;
  bool _holdingEquals = false;
  double _holdProgress = 0;
  Timer? _progressTimer;

  void _tap(String key) {
    setState(() {
      if (key == 'C') {
        _display = '0';
      } else if (key == '=') {
        // short tap — do nothing special
      } else if (key == '⌫') {
        _display = _display.length > 1
            ? _display.substring(0, _display.length - 1)
            : '0';
      } else {
        if (_display == '0') {
          _display = key;
        } else {
          if (_display.length < 12) _display += key;
        }
      }
    });
  }

  void _startHoldEquals() {
    _holdingEquals = true;
    _holdProgress = 0;
    _progressTimer =
        Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!_holdingEquals) {
        t.cancel();
        setState(() => _holdProgress = 0);
        return;
      }
      setState(() => _holdProgress += 50 / 3000);
      if (_holdProgress >= 1.0) {
        t.cancel();
        _unlock();
      }
    });
  }

  void _cancelHoldEquals() {
    _holdingEquals = false;
    _progressTimer?.cancel();
    setState(() => _holdProgress = 0);
  }

  void _unlock() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  static const _bg = Color(0xFF1C1C1E);
  static const _darkBtn = Color(0xFF333333);
  static const _lightBtn = Color(0xFFA5A5A5);
  static const _orange = Color(0xFFFF9500);

  Widget _btn(String label,
      {required Color bg, Color fg = Colors.white, bool isEquals = false}) {
    Widget child = Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: label == '='
            ? Stack(alignment: Alignment.center, children: [
                if (_holdProgress > 0)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: _holdProgress,
                      strokeWidth: 3,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                      backgroundColor: Colors.white24,
                    ),
                  ),
                Text(label,
                    style: TextStyle(
                        color: fg, fontSize: 28, fontWeight: FontWeight.w400)),
              ])
            : Text(label,
                style: TextStyle(
                    color: fg, fontSize: 28, fontWeight: FontWeight.w400)),
      ),
    );

    if (isEquals) {
      return GestureDetector(
        onTap: () => _tap(label),
        onLongPressStart: (_) => _startHoldEquals(),
        onLongPressEnd: (_) => _cancelHoldEquals(),
        child: child,
      );
    }
    return GestureDetector(onTap: () => _tap(label), child: child);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Display
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  child: Text(
                    _display,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w200),
                  ),
                ),
              ),
            ),
            // Hint
            if (_holdingEquals)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Keep holding...',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
              ),
            // Button grid
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _row([
                    _btn('C', bg: _lightBtn, fg: Colors.black),
                    _btn('+/-', bg: _lightBtn, fg: Colors.black),
                    _btn('%', bg: _lightBtn, fg: Colors.black),
                    _btn('÷', bg: _orange),
                  ]),
                  _row([
                    _btn('7', bg: _darkBtn),
                    _btn('8', bg: _darkBtn),
                    _btn('9', bg: _darkBtn),
                    _btn('×', bg: _orange),
                  ]),
                  _row([
                    _btn('4', bg: _darkBtn),
                    _btn('5', bg: _darkBtn),
                    _btn('6', bg: _darkBtn),
                    _btn('-', bg: _orange),
                  ]),
                  _row([
                    _btn('1', bg: _darkBtn),
                    _btn('2', bg: _darkBtn),
                    _btn('3', bg: _darkBtn),
                    _btn('+', bg: _orange),
                  ]),
                  _row([
                    _btn('⌫', bg: _darkBtn),
                    _btn('0', bg: _darkBtn),
                    _btn('.', bg: _darkBtn),
                    _btn('=', bg: _orange, isEquals: true),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> btns) => Expanded(
        child: Row(children: btns.map((b) => Expanded(child: b)).toList()),
      );
}
