import 'package:shared_preferences/shared_preferences.dart';

enum AppMode {
  personal,
  business,
  family,
}

extension AppModeLabel on AppMode {
  String get label {
    switch (this) {
      case AppMode.personal:
        return 'Personal';
      case AppMode.business:
        return 'Business';
      case AppMode.family:
        return 'Family';
    }
  }
}

class Globals {
  static double versionCode = 1.6; //live 1.5

  // Personal mode is the current default behavior.
  static AppMode currentMode = AppMode.personal;
  static String environment = 'prod'; // 'prod' or 'dev'

  /// Whether family mode ships in this build.
  ///
  /// Off by default, so a plain `flutter build apk --release` produces the
  /// personal-only app we publish to the Play Store: no mode switcher, no way
  /// to reach the family screens. Turn it on for internal builds with
  /// `--dart-define=FAMILY_MODE=true`.
  ///
  /// It is a compile-time `const`, so `if (Globals.familyModeEnabled)` is dead
  /// code when off and the family screens are tree-shaken out of the binary
  /// rather than merely hidden.
  static const bool familyModeEnabled =
      bool.fromEnvironment('FAMILY_MODE', defaultValue: false);

  /// The modes the user may switch between in this build. A single entry means
  /// there is nothing to switch, and the picker hides itself.
  static List<AppMode> get selectableModes => [
        AppMode.personal,
        if (familyModeEnabled) AppMode.family,
      ];

  static const String _modeKey = 'app_mode';

  /// Restores the mode the user last switched to. Call once at startup.
  static Future<void> loadPersistedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_modeKey);
      if (stored == null) return;
      final restored = AppMode.values.firstWhere(
        (mode) => mode.name == stored,
        orElse: () => AppMode.personal,
      );
      // Someone who used family mode in an internal build must not land in it
      // after updating to a release that does not ship it.
      currentMode = selectableModes.contains(restored)
          ? restored
          : AppMode.personal;
    } catch (_) {
      // Storage unavailable — personal mode is a safe default.
    }
  }

  /// Switches mode and remembers it across restarts.
  static Future<void> setMode(AppMode mode) async {
    if (!selectableModes.contains(mode)) return;

    currentMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, mode.name);
    } catch (_) {
      // Non-fatal: the switch still applies for this session.
    }
  }
}
