import 'package:get/get.dart';

class Logger {
  static void write(String text, {bool isError = false}) {
    Future.microtask(() => print('** $text. isError: [$isError]'));
  }
  
  static void debug(String message) {
    if (Get.isLogEnable) {
      print('🐛 DEBUG: $message');
    }
  }
  
  static void info(String message) {
    print('ℹ️ INFO: $message');
  }
  
  static void warning(String message) {
    print('⚠️ WARNING: $message');
  }
  
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    print('❌ ERROR: $message');
    if (error != null) print('Error details: $error');
    if (stackTrace != null) print('Stack trace: $stackTrace');
  }
}
