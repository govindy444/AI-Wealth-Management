import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Severity levels exposed by the SDK's logging facade.
enum SdkLogLevel { debug, info, warning, error }


class SdkLogger {
  SdkLogger({
    this.name = 'WealthSdk',
    this.minLevel = SdkLogLevel.debug,
    void Function(SdkLogRecord record)? onRecord,
  }) : _onRecord = onRecord {
    _logger = Logger(name);
  }

  final String name;
  final SdkLogLevel minLevel;
  final void Function(SdkLogRecord record)? _onRecord;
  late final Logger _logger;

  bool _enabled(SdkLogLevel level) => level.index >= minLevel.index;

  void debug(String message, {Object? data}) =>
      _log(SdkLogLevel.debug, message, data: data);

  void info(String message, {Object? data}) =>
      _log(SdkLogLevel.info, message, data: data);

  void warning(String message, {Object? data}) =>
      _log(SdkLogLevel.warning, message, data: data);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(SdkLogLevel.error, message, error: error, stackTrace: stackTrace);

  void _log(
    SdkLogLevel level,
    String message, {
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled(level)) return;

    final record = SdkLogRecord(
      level: level,
      message: message,
      loggerName: name,
      data: data,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );

    _onRecord?.call(record);

    if (kDebugMode) {
      final level0 = switch (level) {
        SdkLogLevel.debug => Level.FINE,
        SdkLogLevel.info => Level.INFO,
        SdkLogLevel.warning => Level.WARNING,
        SdkLogLevel.error => Level.SEVERE,
      };
      _logger.log(level0, record.toString(), error, stackTrace);
    }
  }
}

@immutable
class SdkLogRecord {
  const SdkLogRecord({
    required this.level,
    required this.message,
    required this.loggerName,
    required this.time,
    this.data,
    this.error,
    this.stackTrace,
  });

  final SdkLogLevel level;
  final String message;
  final String loggerName;
  final DateTime time;
  final Object? data;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buf = StringBuffer('[$loggerName] ${level.name.toUpperCase()}: $message');
    if (data != null) buf.write(' | data=$data');
    if (error != null) buf.write(' | error=$error');
    return buf.toString();
  }
}
