class GymSettingsModel {
  final String ownerPhotoBase64;
  final String gymName;
  final String location;
  final List<String> facilities;
  final String reminderTemplate;

  static const String defaultReminderTemplate =
      'Hi {name}, your gym payment of {amount} is due. Please clear your dues at your earliest convenience. Thank you.';

  GymSettingsModel({
    required this.ownerPhotoBase64,
    required this.gymName,
    required this.location,
    required this.facilities,
    required this.reminderTemplate,
  });

  factory GymSettingsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return GymSettingsModel.empty();
    return GymSettingsModel(
      ownerPhotoBase64: map['ownerPhotoBase64'] as String? ?? '',
      gymName: map['gymName'] as String? ?? 'Joji Gym',
      location: map['location'] as String? ?? '',
      facilities: (map['facilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      reminderTemplate:
          map['reminderTemplate'] as String? ?? defaultReminderTemplate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerPhotoBase64': ownerPhotoBase64,
      'gymName': gymName,
      'location': location,
      'facilities': facilities,
      'reminderTemplate': reminderTemplate,
    };
  }

  factory GymSettingsModel.empty() {
    return GymSettingsModel(
      ownerPhotoBase64: '',
      gymName: 'Joji Gym',
      location: '',
      facilities: const [],
      reminderTemplate: defaultReminderTemplate,
    );
  }
}
