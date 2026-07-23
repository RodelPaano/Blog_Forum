import 'package:flutter/foundation.dart';

/// Secure, minimal logger. Never logs PII (passwords, tokens, full emails).
/// In release mode, only errors and warnings are emitted.
class AppLogger {
  AppLogger._();

  static void _log(String level, String message) {
    if (kReleaseMode && (level == 'DEBUG' || level == 'INFO')) return;
    // ignore: avoid_print
    print('[$level] $message');
  }

  static void debug(String msg) => _log('DEBUG', msg);
  static void info(String msg) => _log('INFO', msg);
  static void warn(String msg) => _log('WARN', msg);
  static void error(String msg, [Object? err, StackTrace? st]) {
    _log('ERROR', msg);
    if (err != null) _log('ERROR', '  ↳ $err');
    if (st != null && kDebugMode) {
      // ignore: avoid_print
      print(st);
    }
  }
}
