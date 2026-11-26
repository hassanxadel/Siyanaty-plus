import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/app_theme.dart';

/// Version footnote shown in white at the bottom of the splash.
/// shortcut: bump this when pubspec `version:` changes — not worth a
/// package_info_plus dependency just for a launch footnote.
const String _kVersionLabel = 'Version 1.0.0';

/// Launch splash: the SIYANATY+ wordmark on the app's green, with a minimal
/// car driving through the logo (headlight beam leading), the tagline fading
/// up in yellow and a white version footnote. Background and logo match the
/// native splash (Android/iOS) so the handoff is seamless — no white flash.
///
/// Navigation is NOT driven from here: the splash is a reactive child of
/// [AuthWrapper] (shown while `AuthProvider.isLoading`). The provider holds
/// `isLoading` for at least this animation's length and until auth resolves,
/// so the screen is never cut short and is left exactly once.
class SplashScreen extends StatefulWidget {
  /// Optional callback fired once when the intro animation completes. The
  /// production path (AuthWrapper) doesn't use it; kept for any direct caller.
  final VoidCallback? onFinish;
  const SplashScreen({super.key, this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _car; // 0..1 car travel across the screen
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _versionFade;

  Timer? _slowTimer;
  bool _showSlowIndicator = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _car = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.82, curve: Curves.easeInOutCubic),
    );
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.72, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.80, curve: Curves.easeOutCubic),
    ));
    _versionFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_finished) {
        _finished = true;
        widget.onFinish?.call();
      }
    });
    _controller.forward();

    // Slow-startup affordance: if we're still on screen after ~3s (startup is
    // taking longer than the animation), reveal a subtle yellow indicator.
    _slowTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSlowIndicator = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen, // matches the native splash
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortest = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
            // Logo is a fraction of the shortest side, clamped — never fixed.
            final logoW = (shortest * 0.52).clamp(150.0, 300.0).toDouble();
            final bandH = logoW * 0.80;
            final gap = shortest * 0.045;

            const tagline = DefaultTextStyle(
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: AppTheme.lightBackground, // title → app yellow
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Smart Car Maintenance', maxLines: 1),
              ),
            );

            final version = Text(
              _kVersionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.white.withOpacity(0.7), // value → white
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
            );

            // Car + logo band. The car painter sits BEHIND the logo so the car
            // appears to pass through/behind the wordmark.
            final hero = RepaintBoundary(
              child: SizedBox(
                width: constraints.maxWidth,
                height: bandH,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!reduceMotion)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _car,
                          builder: (_, __) => CustomPaint(
                            painter: _SplashScenePainter(
                              progress: _car.value,
                              rtl: rtl,
                              carColor: AppTheme.lightBackground,
                              roadColor:
                                  AppTheme.lightBackground.withOpacity(0.25),
                              hubColor: AppTheme.backgroundGreen,
                            ),
                          ),
                        ),
                      ),
                    // Box-free logo (the app mark with its square background
                    // keyed out) so the car painter behind it shows through and
                    // the logo sits directly on the green — matches the native
                    // launch screen (@drawable/splash_logo) for a seamless handoff.
                    Image.asset(
                      'assets/images/logo_mark.png',
                      width: logoW,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            );

            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        hero,
                        SizedBox(height: gap),
                        reduceMotion
                            ? tagline
                            : SlideTransition(
                                position: _taglineSlide,
                                child: FadeTransition(
                                    opacity: _taglineFade, child: tagline),
                              ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: shortest * 0.06),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        opacity: _showSlowIndicator ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: const CupertinoActivityIndicator(
                          color: AppTheme.lightBackground,
                        ),
                      ),
                      SizedBox(height: shortest * 0.02),
                      reduceMotion
                          ? version
                          : FadeTransition(opacity: _versionFade, child: version),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Paints the road line, the minimal car and its headlight beam. Every
/// dimension is relative to [size], so it scales to any screen with no
/// absolute pixels. Mirrors travel direction in RTL.
class _SplashScenePainter extends CustomPainter {
  final double progress; // 0..1
  final bool rtl;
  final Color carColor;
  final Color roadColor;
  final Color hubColor;

  _SplashScenePainter({
    required this.progress,
    required this.rtl,
    required this.carColor,
    required this.roadColor,
    required this.hubColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final roadY = size.height * 0.66; // runs through the lower part of the logo

    // Road line (soft inset at the ends).
    canvas.drawLine(
      Offset(size.width * 0.06, roadY),
      Offset(size.width * 0.94, roadY),
      Paint()
        ..color = roadColor
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    final carW = (size.width * 0.17).clamp(44.0, 120.0).toDouble();
    final carH = carW * 0.44;

    final start = -carW;
    final end = size.width + carW;
    final carX =
        rtl ? end - (end - start) * progress : start + (end - start) * progress;
    final cx = carX + carW / 2;
    final dir = rtl ? -1.0 : 1.0;

    final wheelY = roadY;
    final bodyBottom = wheelY - carH * 0.14;
    final bodyTop = bodyBottom - carH;

    // Headlight beam fading out ahead of the car.
    final beamLen = size.width * 0.26;
    final bx = cx + dir * carW * 0.48;
    final beamTopY = bodyTop + carH * 0.25;
    final beamPath = Path()
      ..moveTo(bx, beamTopY)
      ..lineTo(bx + dir * beamLen, beamTopY - carH * 0.55)
      ..lineTo(bx + dir * beamLen, wheelY + carH * 0.25)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(bx, beamTopY),
          Offset(bx + dir * beamLen, beamTopY),
          [carColor.withOpacity(0.33), carColor.withOpacity(0.0)],
        ),
    );

    final paint = Paint()..color = carColor;
    // Lower body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(carX, bodyTop + carH * 0.34, carX + carW, bodyBottom),
        Radius.circular(carH * 0.34),
      ),
      paint,
    );
    // Cabin.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(carX + carW * 0.24, bodyTop, carW * 0.46, carH * 0.52),
        Radius.circular(carH * 0.30),
      ),
      paint,
    );
    // Wheels (green hubs so they read against the yellow car).
    final wheelR = carH * 0.30;
    final hub = Paint()..color = hubColor;
    for (final fx in [carX + carW * 0.27, carX + carW * 0.73]) {
      canvas.drawCircle(Offset(fx, wheelY), wheelR, paint);
      canvas.drawCircle(Offset(fx, wheelY), wheelR * 0.42, hub);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashScenePainter old) =>
      old.progress != progress || old.rtl != rtl;
}
