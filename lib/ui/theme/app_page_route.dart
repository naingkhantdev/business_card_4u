import 'package:flutter/material.dart';

/// [MaterialPageRoute] with the app's timing: opening a page takes a little
/// longer than closing one.
///
/// The animation itself comes from the theme (SmoothPageTransitionsBuilder).
/// Only the timing lives here, because a theme transition can't set its own
/// duration. At the stock 300ms the fade-through's opening felt rushed —
/// its content only starts appearing a third of the way in — while going
/// back at 300ms already felt right.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);
}
