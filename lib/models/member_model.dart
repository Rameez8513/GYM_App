import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberStatus { active, inactive }

enum Gender { male, female }

class MemberModel {
  final String id;
  final String name;
  final Gender gender;
  final String whatsappNumber;
  final String? photoUrl;
  final DateTime dateOfBirth;
  final String cnicNumber;
  final String profession;
  final String address;
  final DateTime joinDate;
  final String planId;
  final String planName;
  final int planDurationDays;
  final double feeAmount;
  final DateTime nextDueDate;
  final MemberStatus status;
  final bool currentMonthPaid;
  final DateTime createdAt;

  MemberModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.whatsappNumber,
    this.photoUrl,
    required this.dateOfBirth,
    required this.cnicNumber,
    required this.profession,
    required this.address,
    required this.joinDate,
    required this.planId,
    required this.planName,
    this.planDurationDays = 30,
    required this.feeAmount,
    required this.nextDueDate,
    required this.status,
    required this.currentMonthPaid,
    required this.createdAt,
  });

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !currentMonthPaid && nextDueDate.isBefore(today);
  }

  bool get isExpiringSoon {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = nextDueDate.difference(today).inDays;
    return !currentMonthPaid && diff >= 0 && diff <= 7;
  }

  factory MemberModel.fromMap(String id, Map<String, dynamic> map) {
    return MemberModel(
      id: id,
      name: map['name'] as String? ?? '',
      gender: (map['gender'] as String? ?? 'male') == 'male'
          ? Gender.male
          : Gender.female,
      whatsappNumber: map['whatsappNumber'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      dateOfBirth:
          (map['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime(2000, 1, 1),
      cnicNumber: map['cnicNumber'] as String? ?? '',
      profession: map['profession'] as String? ?? '',
      address: map['address'] as String? ?? '',
      joinDate: (map['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      planId: map['planId'] as String? ?? '',
      planName: map['planName'] as String? ?? '',
      planDurationDays: map['planDurationDays'] as int? ?? 30,
      feeAmount: (map['feeAmount'] as num?)?.toDouble() ?? 0,
      nextDueDate:
          (map['nextDueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: (map['status'] as String? ?? 'active') == 'active'
          ? MemberStatus.active
          : MemberStatus.inactive,
      currentMonthPaid: map['currentMonthPaid'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender == Gender.male ? 'male' : 'female',
      'whatsappNumber': whatsappNumber,
      'photoUrl': photoUrl,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'cnicNumber': cnicNumber,
      'profession': profession,
      'address': address,
      'joinDate': Timestamp.fromDate(joinDate),
      'planId': planId,
      'planName': planName,
      'planDurationDays': planDurationDays,
      'feeAmount': feeAmount,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'status': status == MemberStatus.active ? 'active' : 'inactive',
      'currentMonthPaid': currentMonthPaid,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MemberModel copyWith({
    String? name,
    Gender? gender,
    String? whatsappNumber,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? cnicNumber,
    String? profession,
    String? address,
    DateTime? joinDate,
    String? planId,
    String? planName,
    int? planDurationDays,
    double? feeAmount,
    DateTime? nextDueDate,
    MemberStatus? status,
    bool? currentMonthPaid,
  }) {
    return MemberModel(
      id: id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      profession: profession ?? this.profession,
      address: address ?? this.address,
      joinDate: joinDate ?? this.joinDate,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      planDurationDays: planDurationDays ?? this.planDurationDays,
      feeAmount: feeAmount ?? this.feeAmount,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      status: status ?? this.status,
      currentMonthPaid: currentMonthPaid ?? this.currentMonthPaid,
      createdAt: createdAt,
    );
  }
}
