import 'package:flutter/material.dart';

/// The app's page transition: a short slide with a "fade through".
///
/// The incoming page first lays down a solid background over the old page,
/// and only once that is mostly opaque does its own content fade in. So the
/// two pages' text is never visible at the same time — fading the whole new
/// page in over the old one (the first version of this) showed both pages'
/// text overlapping for the first half of the animation.
///
/// Going back plays it in reverse: the content fades out first, then the
/// background clears to reveal the page underneath.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  static final _enter = Tween<Offset>(
    begin: const Offset(0.05, 0),
    end: Offset.zero,
  );
  static final _exit = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.04, 0),
  );

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideIn = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // The backdrop covers the old page in the first 40%...
    final backdropIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    // ...and the new content only starts once it mostly has.
    final contentIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    final slideOut = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return SlideTransition(
      position: _exit.animate(slideOut),
      child: SlideTransition(
        position: _enter.animate(slideIn),
        child: FadeTransition(
          opacity: backdropIn,
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: FadeTransition(opacity: contentIn, child: child),
          ),
        ),
      ),
    );
  }
}
