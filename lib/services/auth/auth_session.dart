import 'package:flutter/foundation.dart';

class AuthSession {
  static final ValueNotifier<int> unauthorizedTick = ValueNotifier<int>(0);

  static void notifyUnauthorized() {
    unauthorizedTick.value = unauthorizedTick.value + 1;
  }
}

