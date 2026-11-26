import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/constants/app_theme.dart';
import '../../actions/app_action.dart';
import '../../widgets/screen_with_nav_bar.dart';

/// All Actions — every tool in the app as one flat grid, 3 cards per row.
///
/// Reads from the shared [kAppActions] registry (the same source as the Home
/// Actions tiles) in a fixed display order, under the app's standard page
/// header. The grid uses a fixed main-axis extent (not an aspect ratio) so it
/// can never overflow on small screens.
class AllActionsScreen extends StatefulWidget {
  const AllActionsScreen({super.key});

  @override
  State<AllActionsScreen> createState() => _AllActionsScreenState();
}

/// Display order on this screen (ids from [kAppActions]). Home has its own
/// order via `homeActions`, so changing this list does not affect Home.
const List<String> _displayOrder = <String>[
  'vin_lookup', 'car_health', 'maintenance', // row 1
  'mileage_track', 'service_centers', 'voice_notes', // row 2
  'ocr_scanner', 'obd', 'service_reminders', // row 3
];

class _AllActionsScreenState extends State<AllActionsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  )..forward();

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  /// Actions in display order; any registry action not listed is appended so a
  /// newly added tool can't silently disappear from this screen.
  List<AppAction> get _ordered {
    final byId = {for (final a in kAppActions) a.id: a};
    final ordered = <AppAction>[
      for (final id in _displayOrder)
        if (byId[id] != null) byId[id]!,
    ];
    final listed = _displayOrder.toSet();
    ordered.addAll(kAppActions.where((a) => !listed.contains(a.id)));
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final actions = _ordered;

    return ScreenWithNavBar(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGreen,
        body: Column(
          children: [
            const _Header(),
            Expanded(
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 cards per row
                  mainAxisExtent: 150, // fixed height → no overflow, text ellipsizes
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: actions.length,
                itemBuilder: (context, i) => _introWrap(
                  i,
                  reduceMotion,
                  _ActionTile(
                    action: actions[i],
                    reduceMotion: reduceMotion,
                    onTap: () => _open(actions[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Staggered fade/slide-in on first load; a no-op when reduce-motion is on.
  Widget _introWrap(int index, bool reduceMotion, Widget child) {
    if (reduceMotion) return child;
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, c) {
        final start = (index * 0.05).clamp(0.0, 0.6);
        final t = Curves.easeOut.transform(
          ((_introController.value - start) / (1 - start)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: c),
        );
      },
      child: child,
    );
  }

  void _open(AppAction action) {
    Navigator.of(context).push(MaterialPageRoute(builder: action.builder));
  }
}

/// The app's standard page header — rounded-bottom green gradient, back arrow,
/// centered title, subtitle. Title is app-yellow ([AppTheme.lightBackground]).
/// Keep this header style consistent across screens; do not restyle it.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      // 200 is a minimum, not a fixed height, so the header keeps its look at
      // normal text size but grows (instead of overflowing) at large scales.
      constraints: const BoxConstraints(minHeight: 200),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundGreen,
            AppTheme.darkAccentGreen,
            AppTheme.primaryGreen,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expanded title between two equal-width controls keeps the
              // title optically centred on the screen.
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Back',
                    icon: const Icon(CupertinoIcons.back,
                        color: Colors.white, size: 28),
                  ),
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'All Actions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightBackground, // app-yellow title
                          fontFamily: 'Orbitron',
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Complete suite of vehicle management tools',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single action card: shared yellow-bordered surface, colored icon badge,
/// yellow name, white description, with an iOS press-scale and haptic.
class _ActionTile extends StatefulWidget {
  final AppAction action;
  final VoidCallback onTap;
  final bool reduceMotion;

  const _ActionTile({
    required this.action,
    required this.onTap,
    required this.reduceMotion,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return Semantics(
      button: true,
      label: '${a.title}. ${a.subtitle}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: (_pressed && !widget.reduceMotion) ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: AppTheme.carCardDecoration(radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: a.iconColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(a.icon, color: a.iconColor, size: 21),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    a.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.lightBackground, // name is yellow
                      fontFamily: 'Orbitron',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    a.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7), // description white
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
