class ApiConfig {
  static const bool isEmulator = bool.fromEnvironment('IS_EMULATOR', defaultValue: false);

  static String get baseUrl {
    if (isEmulator) {
      return "http://10.0.2.2:8080";
    } else {
      return "http://192.168.0.102:8080";
    }
  }
}
