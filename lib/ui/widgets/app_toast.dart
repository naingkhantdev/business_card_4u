import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_typography.dart';
import '../theme/glass.dart';
import '../theme/wallet_tokens.dart';

enum AppToastType {
  info,
  success,
  warning,
  error,
  destructiveSoft,
}

/// A frosted bar with a signal rule down its leading edge.
///
/// The panel is neutral glass and status is carried by a 3px keyline, so
/// severity scales with how much colour you see. Filling the whole bar with
/// the status colour — what this used to do — made an ordinary "saved"
/// confirmation the loudest thing on screen for the least important message.
///
/// Motion is not decoration here. An error that appears and disappears
/// instantly is easy to miss entirely, which is the failure mode that matters:
/// the user retries, hits the same error, and never learns why. So the bar
/// springs in, drains a visible timer, holds while touched, and eases out.
class AppToast {
  const AppToast._();

  /// Only one bar exists at a time. They all anchor to the same spot, so a
  /// second one would render on top of the first and both become unreadable.
  static _ToastHandle? _current;

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration? duration,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    // Taken now: the overlay sits above the route, so resolving the theme
    // inside the entry can miss a locally scoped one.
    final theme = Theme.of(context);

    // The outgoing bar goes without ceremony. Animating it out while the new
    // one animates in would cross-fade two bars in the same position.
    _current?.removeNow();

    _feedbackFor(type);

    late final _ToastHandle handle;

    handle = _ToastHandle(
      remove: () {
        if (identical(_current, handle)) _current = null;
      },
    );

    final entry = OverlayEntry(
      // Positioned must be the direct child here: the overlay lays its
      // entries out like a Stack, and a Positioned under any other widget
      // throws. Full-bleed left/right so the bar spans the screen.
      builder: (_) => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Theme(
          data: theme,
          child: _ToastBody(
            message: message,
            type: type,
            duration: duration ?? _defaultDurationForType(type),
            onGone: handle.removeNow,
          ),
        ),
      ),
    );

    handle.entry = entry;

    _current = handle;
    overlay.insert(entry);
  }

  /// Errors get a firmer tap than warnings; the quiet types get none. A
  /// success buzz on every save turns into background noise fast.
  static void _feedbackFor(AppToastType type) {
    switch (type) {
      case AppToastType.error:
        HapticFeedback.mediumImpact();
      case AppToastType.warning:
      case AppToastType.destructiveSoft:
        HapticFeedback.lightImpact();
      case AppToastType.success:
      case AppToastType.info:
        break;
    }
  }

  static Duration _defaultDurationForType(AppToastType type) {
    switch (type) {
      case AppToastType.error:
      case AppToastType.warning:
        return const Duration(seconds: 5);
      case AppToastType.destructiveSoft:
        return const Duration(seconds: 4);
      case AppToastType.success:
      case AppToastType.info:
        return const Duration(seconds: 3);
    }
  }
}

class _ToastHandle {
  OverlayEntry? entry;
  final VoidCallback remove;

  _ToastHandle({required this.remove});

  void removeNow() {
    entry?.remove();
    entry = null;
    remove();
  }
}

class _ToastBody extends StatefulWidget {
  final String message;
  final AppToastType type;
  final Duration duration;

  /// Called once the exit animation has finished, to pull the overlay entry.
  final VoidCallback onGone;

  const _ToastBody({
    required this.message,
    required this.type,
    required this.duration,
    required this.onGone,
  });

  @override
  State<_ToastBody> createState() => _ToastBodyState();
}

class _ToastBodyState extends State<_ToastBody> with TickerProviderStateMixin {
  /// Entrance and exit. Reversing it is what plays the exit, which is why the
  /// overlay entry cannot simply be removed on a timer.
  late final AnimationController _enter;

  /// Doubles as the dismiss timer and the drain bar. Driving both from one
  /// controller is what makes hold-to-pause free — stopping the animation
  /// stops the countdown, because they are the same thing.
  late final AnimationController _life;

  late final Animation<double> _slide;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  /// Vertical drag distance, in pixels, while the user is flicking it away.
  double _dragY = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 220),
    );

    // Overshoots and settles. A linear rise reads as a panel being drawn;
    // the back-ease reads as something arriving.
    _slide = Tween(begin: 34.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _scale = Tween(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    // Opacity leads on the way in and out, so the bar never appears to slide
    // while fully transparent.
    _fade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0, .55, curve: Curves.easeOut),
      reverseCurve: const Interval(.35, 1, curve: Curves.easeIn),
    );

    _life = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _close();
      });

    _enter.forward();
    _life.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _life.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _life.stop();
    try {
      await _enter.reverse().orCancel;
    } on TickerCanceled {
      // Disposed mid-exit — the entry is already going away.
      return;
    }
    if (mounted) widget.onGone();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    // Downward only. Dragging up would lift it off the bottom edge it is
    // anchored to, which has nowhere to go.
    setState(() => _dragY = (_dragY + d.delta.dy).clamp(0.0, 200.0));
    _life.stop();
  }

  void _onDragEnd(DragEndDetails d) {
    final flung = d.velocity.pixelsPerSecond.dy > 420;
    if (flung || _dragY > 44) {
      _close();
      return;
    }
    setState(() => _dragY = 0);
    // Put the remaining time back on the clock rather than restarting it.
    if (!_closing) _life.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rule = _ruleColor(widget.type, isDark);
    final ink = _inkColor(widget.type, isDark);

    // Sit above the keyboard when one is open, or the bar reports an error
    // about the field the user cannot see it next to.
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Wallet.margin,
          0,
          Wallet.margin,
          24 + keyboard,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_enter, _life]),
          builder: (context, child) {
            // Resisted drag: the bar lags the finger past ~60px so it feels
            // attached rather than free.
            final drag = _dragY <= 60 ? _dragY : 60 + (_dragY - 60) * .35;

            return Transform.translate(
              offset: Offset(0, _slide.value + drag),
              child: Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: _fade.value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _close,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              // Holding still is how you read a long error, so the clock
              // stops while a finger is down and resumes when it lifts.
              onLongPressStart: (_) => _life.stop(),
              onLongPressEnd: (_) {
                if (!_closing) _life.forward();
              },
              child: GlassPanel(
                rule: rule,
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_icon(widget.type), size: 17, color: rule),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.message,
                              style: AppTypography.secondary(TextStyle(
                                color: ink,
                                fontSize: 13.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              )),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // The clock, made visible. Without it a bar that
                    // disappears mid-sentence looks like a glitch rather
                    // than a timer running out.
                    SizedBox(
                      height: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (1 - _life.value).clamp(0.0, 1.0),
                          child: ColoredBox(color: rule.withOpacity(.55)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _icon(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return Icons.check_circle_outline_rounded;
      case AppToastType.warning:
        return Icons.warning_amber_rounded;
      case AppToastType.error:
      case AppToastType.destructiveSoft:
        return Icons.error_outline_rounded;
      case AppToastType.info:
        return Icons.info_outline_rounded;
    }
  }

  static Color _ruleColor(AppToastType type, bool isDark) {
    switch (type) {
      case AppToastType.success:
        return Wallet.success;
      case AppToastType.warning:
        return Wallet.pending;
      case AppToastType.error:
      case AppToastType.destructiveSoft:
        return Wallet.danger;
      case AppToastType.info:
        return Wallet.accentOf(isDark);
    }
  }

  /// Message text stays ink, not the status colour — coloured body copy is
  /// harder to read and the rule has already said what kind of message it is.
  /// The one exception is a hard error, where the text carries the tone too.
  static Color _inkColor(AppToastType type, bool isDark) {
    if (type == AppToastType.error) {
      return isDark ? const Color(0xFFFECACA) : const Color(0xFF7F1D1D);
    }
    return Wallet.inkOf(isDark);
  }
}
