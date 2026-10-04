import 'package:cloud_firestore/cloud_firestore.dart';

class PlanModel {
  final String id;
  final String name;
  final double price;
  final int durationInDays;
  final bool isActive;
  final DateTime createdAt;

  PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationInDays,
    required this.isActive,
    required this.createdAt,
  });

  factory PlanModel.fromMap(String id, Map<String, dynamic> map) {
    return PlanModel(
      id: id,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      durationInDays: map['durationInDays'] as int? ?? 30,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationInDays': durationInDays,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PlanModel copyWith({
    String? name,
    double? price,
    int? durationInDays,
    bool? isActive,
  }) {
    return PlanModel(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      durationInDays: durationInDays ?? this.durationInDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
