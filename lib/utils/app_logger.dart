import 'dart:developer' as developer;

class AppLogger {
  static const String _tag = 'HotelExpenseTracker';

  static void d(String message, {String tag = _tag}) {
    developer.log(
      message,
      name: tag,
      level: 250, // Level.fine
    );
  }

  static void i(String message, {String tag = _tag}) {
    developer.log(
      message,
      name: tag,
      level: 800, // Level.info
    );
  }

  static void w(String message, {String tag = _tag}) {
    developer.log(
      message,
      name: tag,
      level: 900, // Level.warning
    );
  }

  static void e(String message, {String tag = _tag, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag,
      level: 1000, // Level.severe
      error: message,
      stackTrace: stackTrace,
    );
  }

  static void functionEntry(String functionName,
      {String tag = _tag, Map<String, dynamic>? params}) {
    String logMessage = '→ $functionName';
    if (params != null && params.isNotEmpty) {
      logMessage += '(${_formatParams(params)})';
    }
    developer.log(
      logMessage,
      name: tag,
      level: 300, // Level.finer (function entry)
    );
  }

  static void functionExit(String functionName,
      {String tag = _tag, dynamic result}) {
    String logMessage = '← $functionName';
    if (result != null) {
      logMessage += ' result: $result';
    }
    developer.log(
      logMessage,
      name: tag,
      level: 300, // Level.finer (function exit)
    );
  }

  static String _formatParams(Map<String, dynamic> params) {
    final List<String> paramStrings = [];
    params.forEach((key, value) {
      paramStrings.add('$key: $value');
    });
    return paramStrings.join(', ');
  }

  static void networkCall(String method, String url,
      {String tag = _tag, dynamic data}) {
    developer.log(
      '🌐 $method $url ${data != null ? 'with data: $data' : ''}',
      name: tag,
      level: 500, // Level.config
    );
  }

  static void databaseOperation(String operation, String table,
      {String tag = _tag, dynamic criteria}) {
    developer.log(
      '🗄️ $operation on $table ${criteria != null ? 'with criteria: $criteria' : ''}',
      name: tag,
      level: 500, // Level.config
    );
  }
}
