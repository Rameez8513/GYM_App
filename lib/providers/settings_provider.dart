import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/gym_settings_model.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();
  StreamSubscription<GymSettingsModel>? _sub;

  GymSettingsModel _settings = GymSettingsModel.empty();
  Uint8List? _photoBytes;
  bool _isSavingPhoto = false;

  GymSettingsModel get settings => _settings;
  Uint8List? get ownerPhotoBytes => _photoBytes;
  bool get isSavingPhoto => _isSavingPhoto;

  void bind(bool loggedIn) {
    if (loggedIn) {
      if (_sub != null) return;
      _sub = _service.streamSettings().listen((settings) {
        _settings = settings;
        _photoBytes = _decode(settings.ownerPhotoBase64);
        notifyListeners();
      }, onError: (_) {});
    } else {
      _sub?.cancel();
      _sub = null;
      _settings = GymSettingsModel.empty();
      _photoBytes = null;
    }
  }

  Uint8List? _decode(String value) {
    if (value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOwnerPhoto(Uint8List bytes) async {
    _isSavingPhoto = true;
    notifyListeners();
    try {
      await _service.saveOwnerPhoto(bytes);
    } finally {
      _isSavingPhoto = false;
      notifyListeners();
    }
  }

  Future<void> removeOwnerPhoto() async {
    _isSavingPhoto = true;
    notifyListeners();
    try {
      await _service.removeOwnerPhoto();
    } finally {
      _isSavingPhoto = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(
      {required String gymName,
      required String location,
      required List<String> facilities}) {
    return _service.updateProfile(
        gymName: gymName, location: location, facilities: facilities);
  }

  Future<void> saveReminderTemplate(String template) {
    return _service.updateReminderTemplate(template);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
