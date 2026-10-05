enum Environment { local, prod }

class ApiConstants {
  /// Change only here.
  static const Environment current = Environment.prod;

  static String get baseUrl {
    switch (current) {
      case Environment.local:
        return 'http://192.168.1.21:4000';
      case Environment.prod:
        return 'https://payreceipt.immortalgroup.in';
    }
  }
}
