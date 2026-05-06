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
  static double versionCode = 1.5; //live 1.5

  // Personal mode is the current default behavior.
  static AppMode currentMode = AppMode.personal;
  static String environment = 'dev'; // 'prod' or 'dev'
}
