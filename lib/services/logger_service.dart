import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error }

class LoggerService {
  static void log({
    required String action,
    required LogLevel level,
    String? message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = level == LogLevel.error
        ? '🔴 [ERROR]'
        : level == LogLevel.warning
            ? '🟠 [WARNING]'
            : '🔵 [INFO]';

    final buffer = StringBuffer()
      ..write('$prefix [$timestamp] Action: $action');

    if (message != null) {
      buffer.write(' | Message: $message');
    }

    if (exception != null) {
      buffer.write(' | Exception: $exception');
    }

    debugPrint(buffer.toString());

    if (stackTrace != null && kDebugMode) {
      debugPrint('StackTrace:\n$stackTrace');
    }
  }

  static void info(String action, [String? message]) {
    log(action: action, level: LogLevel.info, message: message);
  }

  static void warning(String action, [String? message, Object? exception]) {
    log(action: action, level: LogLevel.warning, message: message, exception: exception);
  }

  static void error(String action, [String? message, Object? exception, StackTrace? stackTrace]) {
    log(action: action, level: LogLevel.error, message: message, exception: exception, stackTrace: stackTrace);
  }
}
