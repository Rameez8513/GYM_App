import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gym_settings_model.dart';

class SettingsService {
  final DocumentReference<Map<String, dynamic>> _settingsDoc =
      FirebaseFirestore.instance.collection('settings').doc('gym_profile');

  static const int _maxBytes = 600 * 1024;

  Stream<GymSettingsModel> streamSettings() {
    return _settingsDoc
        .snapshots()
        .map((doc) => GymSettingsModel.fromMap(doc.data()));
  }

  Future<void> saveOwnerPhoto(Uint8List bytes) {
    if (bytes.length > _maxBytes) {
      throw Exception('photo-too-large');
    }
    return _settingsDoc.set(
        {'ownerPhotoBase64': base64Encode(bytes)}, SetOptions(merge: true));
  }

  Future<void> removeOwnerPhoto() {
    return _settingsDoc.set({'ownerPhotoBase64': ''}, SetOptions(merge: true));
  }

  Future<void> updateProfile({
    required String gymName,
    required String location,
    required List<String> facilities,
  }) {
    return _settingsDoc.set({
      'gymName': gymName,
      'location': location,
      'facilities': facilities,
    }, SetOptions(merge: true));
  }

  Future<void> updateReminderTemplate(String template) {
    return _settingsDoc
        .set({'reminderTemplate': template}, SetOptions(merge: true));
  }
}
