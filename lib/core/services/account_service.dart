import 'package:flutter/services.dart';

/// Reads Google accounts registered on the device via AccountManager.
/// Works reliably on Android < 8. On Android 8+, may return empty if the
/// OS restricts cross-app account visibility — in that case the screen
/// falls back to the Google Sign-In flow.
class AccountService {
  AccountService._();

  static const _channel = MethodChannel('kuet_bus/accounts');

  static Future<List<String>> getGoogleAccounts() async {
    try {
      final result = await _channel.invokeListMethod<String>('getGoogleAccounts');
      return result ?? [];
    } on PlatformException {
      return [];
    }
  }
}
