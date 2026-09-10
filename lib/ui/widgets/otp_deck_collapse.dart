import 'dart:math' as math;

import 'package:flutter/material.dart';

/// OTP slots that swing inward and settle as a fanned card deck.
///
/// Usage:
/// ```dart
/// OtpDeckCollapse(
///   value: _otpController.text,
///   isComplete: _otpController.text.length == 4,
///   onSettled: _verifyOtp,
/// )
/// ```
///
/// Two decisions shape the whole implementation:
///
/// **There is no Row.** Swapping a `Row` for a `Stack` when the animation
/// starts would reparent every card on the trigger frame, and the one-frame
/// jump that produces is exactly what the animation is meant to hide. This is
/// a `Stack` from the first build, with each card translated to the position a
/// `Row` would have given it. At `t = 0` the two are pixel-identical, so there
/// is nothing to transition between — only a translation to drive to zero.
///
/// **The fan is a consequence, not a layout.** Every card converges on dead
/// centre; the splay comes from rotating about [pivotAlignment], a point well
/// below the card. That long arm turns a few degrees of rotation into real
/// lateral displacement, so the cards deal themselves out. Placing the fan by
/// hand and rotating in place would land the same final frame, but the cards
/// would slide rather than swing on the way there.
class OtpDeckCollapse extends StatefulWidget {
  /// The digits entered so far. Shorter than [length] renders empty slots.
  final String value;

  /// Drives the animation. False collapses back out to the row.
  final bool isComplete;

  /// Fires once the deck has settled — a good hook for the verify call, so
  /// the request goes out after the motion rather than competing with it.
  final VoidCallback? onSettled;

  final int length;
  final double slotWidth;
  final double slotHeight;
  final double gap;

  /// Total sweep of the fan, in radians, from the first card to the last.
  /// 0.48 puts the outermost pair at about ±14°.
  final double fanSpread;

  /// Rotation origin, in units of half the card height below its centre.
  /// The default hangs the pivot roughly 100px under a 64px card — long
  /// enough that the swing reads as a pendulum rather than a spin.
  final double pivotAlignment;

  /// Peak of the mid-flight lift, in logical pixels. This is what bows the
  /// path into an arc; without it the cards would travel a straight line and
  /// merely happen to be rotating.
  final double arcLift;

  final Duration duration;

  /// Fraction of the timeline each successive card is delayed by, so the row
  /// ripples inward instead of collapsing as one block.
  final double stagger;

  final Color? cardColor;
  final Color? borderColor;
  final TextStyle? digitStyle;

  const OtpDeckCollapse({
    super.key,
    required this.value,
    required this.isComplete,
    this.onSettled,
    this.length = 4,
    this.slotWidth = 56,
    this.slotHeight = 64,
    this.gap = 12,
    this.fanSpread = 0.48,
    this.pivotAlignment = 3.2,
    this.arcLift = 18,
    this.duration = const Duration(milliseconds: 900),
    this.stagger = 0.10,
    this.cardColor,
    this.borderColor,
    this.digitStyle,
  });

  @override
  State<OtpDeckCollapse> createState() => _OtpDeckCollapseState();
}

class _OtpDeckCollapseState extends State<OtpDeckCollapse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// One curved animation per card, each shifted along the shared timeline.
  ///
  /// Typed as `CurvedAnimation` rather than `Animation` so they can be
  /// disposed: every one registers a listener on the controller, and
  /// [_buildIntervals] can be called again when the length or stagger
  /// changes. Replacing the list without disposing would leave the old
  /// listeners attached for the life of the controller.
  late List<CurvedAnimation> _progress;

  /// `_progress` is `late`, so the first `_buildIntervals` call has nothing to
  /// dispose and must not read it.
  bool _progressReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _buildIntervals();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onSettled?.call();
    });

    // Respect a widget that is built already-complete (a rebuild after a hot
    // reload, or a restored screen) instead of animating from scratch.
    if (widget.isComplete) _controller.value = 1;
  }

  void _buildIntervals() {
    // Detach the previous set first; see the field doc.
    if (_progressReady) {
      for (final a in _progress) {
        a.dispose();
      }
    }

    final n = widget.length;

    // The last card still needs the full remaining span to finish inside the
    // controller, so the usable window shrinks as the stagger grows. Clamped
    // because a large stagger on many cards would otherwise ask for a
    // negative-length interval, which Interval asserts on.
    final totalDelay = (n - 1) * widget.stagger;
    final span = (1.0 - totalDelay).clamp(0.15, 1.0);

    _progress = List.generate(n, (i) {
      final begin = (i * widget.stagger).clamp(0.0, 1.0 - span);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, begin + span, curve: Curves.easeInOutCubic),
      );
    });
    _progressReady = true;
  }

  @override
  void didUpdateWidget(covariant OtpDeckCollapse old) {
    super.didUpdateWidget(old);

    if (old.length != widget.length || old.stagger != widget.stagger) {
      _buildIntervals();
    }
    if (old.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (old.isComplete != widget.isComplete) {
      widget.isComplete ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    for (final a in _progress) {
      a.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  /// Where card [i] sits at rest, measured from the centre of the stack.
  /// This is the `Row` the widget never actually builds.
  double _restDx(int i) =>
      (i - (widget.length - 1) / 2) * (widget.slotWidth + widget.gap);

  /// Resting fan angle for card [i], spread evenly across [fanSpread].
  double _fanAngle(int i) {
    if (widget.length < 2) return 0;
    final step = widget.fanSpread / (widget.length - 1);
    return (i - (widget.length - 1) / 2) * step;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final card = widget.cardColor ??
        (isDark ? const Color(0xFF202026) : Colors.white);
    final border = widget.borderColor ??
        (isDark ? const Color(0xFF3A3A43) : const Color(0xFFE4E4E7));
    final digit = widget.digitStyle ??
        theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1,
        ) ??
        const TextStyle(fontSize: 24, fontWeight: FontWeight.w600);

    // The stack has to stay wide enough for the resting row, or the outermost
    // cards are clipped before the animation has a chance to pull them in.
    final rowWidth = widget.length * widget.slotWidth +
        (widget.length - 1) * widget.gap;

    return SizedBox(
      width: rowWidth,
      // Headroom for the mid-flight lift, which travels above the row.
      height: widget.slotHeight + widget.arcLift,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Painted in index order, so later cards land on top of earlier
              // ones — the overlap a real deck has.
              for (var i = 0; i < widget.length; i++)
                _buildCard(i, card, border, digit),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(int i, Color card, Color border, TextStyle digit) {
    final t = _progress[i].value;

    // Back-eased so the card overshoots its fan angle a touch and snaps in,
    // the way a dealt card does. Only the rotation gets this; overshooting
    // the translation would make the deck visibly miss centre.
    final rotT = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));

    final dx = _restDx(i) * (1 - t);

    // A half-sine peaks mid-flight and returns to zero, which is what bows
    // the path. Negative is upward.
    final dy = -math.sin(t * math.pi) * widget.arcLift;

    final angle = _fanAngle(i) * rotT;

    // Cards lift toward the viewer as they gather.
    final scale = 1 + 0.06 * t;

    final char = i < widget.value.length ? widget.value[i] : '';

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.scale(
        scale: scale,
        child: Transform.rotate(
          angle: angle,
          // The whole trick. Rotating about a point this far below the card
          // sweeps it along an arc and displaces it sideways, which is what
          // deals the fan out.
          alignment: Alignment(0, widget.pivotAlignment),
          child: Container(
            width: widget.slotWidth,
            height: widget.slotHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
              // Flat in the row, lifted in the deck: the shadow arrives with
              // the motion so the cards read as coming off the page.
              boxShadow: t == 0
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18 * t),
                        blurRadius: 16 * t,
                        offset: Offset(0, 6 * t),
                        spreadRadius: -2,
                      ),
                    ],
            ),
            child: Text(char, style: digit),
          ),
        ),
      ),
    );
  }
}
