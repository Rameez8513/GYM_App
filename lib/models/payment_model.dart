import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { cash, online }

class PaymentModel {
  final String id;
  final String memberId;
  final String memberName;
  final double amount;
  final DateTime paidDate;
  final PaymentMethod method;
  final String monthLabel;
  final DateTime createdAt;
  final bool isPaid;

  PaymentModel({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.paidDate,
    required this.method,
    required this.monthLabel,
    required this.createdAt,
    this.isPaid = true,
  });

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      id: id,
      memberId: map['memberId'] as String? ?? '',
      memberName: map['memberName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paidDate: (map['paidDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      method: (map['method'] as String? ?? 'cash') == 'cash'
          ? PaymentMethod.cash
          : PaymentMethod.online,
      monthLabel: map['monthLabel'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPaid: map['isPaid'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'paidDate': Timestamp.fromDate(paidDate),
      'method': method == PaymentMethod.cash ? 'cash' : 'online',
      'monthLabel': monthLabel,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPaid': isPaid,
    };
  }
}
