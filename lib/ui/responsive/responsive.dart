import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// A single switch each page checks to decide between its existing mobile
/// layout and a wide-screen desktop one. Native mobile builds always read
/// `false` here — only a browser window past the breakpoint gets the
/// desktop branch, so the phone experience never changes.
class Responsive {
  const Responsive._();

  static const double desktopBreakpoint = 900;

  static bool isDesktop(BuildContext context) =>
      kIsWeb && MediaQuery.sizeOf(context).width >= desktopBreakpoint;
}
