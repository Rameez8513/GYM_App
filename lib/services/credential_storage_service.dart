import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';

  Future<({String email, String password})?> read() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      if (email == null || password == null) return null;
      return (email: email, password: password);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String email, String password) async {
    try {
      await _storage.write(key: _emailKey, value: email);
      await _storage.write(key: _passwordKey, value: password);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
    } catch (_) {}
  }
}
