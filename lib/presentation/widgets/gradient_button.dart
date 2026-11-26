import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/constants/app_theme.dart';

/// The app's single primary button.
///
/// Uses the shared [AppTheme.primaryButtonDecoration] (the dark-green vertical
/// gradient + yellow [AppTheme.lightBackground] frame + soft glow) with a white
/// Orbitron label, an iOS-style pressed state (scale + dim), a light haptic, and
/// an inline [CupertinoActivityIndicator] while [isLoading]. Reuse this for every
/// primary action so buttons never drift apart.
///
/// Note: the shared gradient is dark, so the label is WHITE for contrast (as the
/// decoration's own contract specifies) rather than [AppTheme.backgroundGreen],
/// which would be invisible on it.
class GradientButton extends StatefulWidget {
  final String label;

  /// Null disables the button (dimmed, no haptic, no tap).
  final VoidCallback? onPressed;

  /// Shows a spinner in place of the label and blocks taps.
  final bool isLoading;

  final IconData? icon;

  /// Full width (capped by [maxWidth]) when true; sized to content when false.
  final bool expand;
  final double maxWidth;
  final double radius;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
    this.maxWidth = 440,
    this.radius = 16,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool value) {
    if (!_enabled) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.isLoading
        ? const CupertinoActivityIndicator(color: Colors.white)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          );

    Widget button = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 120),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52), // ≥44pt tap target
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: AppTheme.primaryButtonDecoration(radius: widget.radius),
          child: content,
        ),
      ),
    );

    button = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: _enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: button,
      ),
    );

    if (!widget.expand) return button;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: SizedBox(width: double.infinity, child: button),
      ),
    );
  }
}
