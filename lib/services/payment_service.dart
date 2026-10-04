import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../models/payment_model.dart';

class PaymentService {
  final CollectionReference<Map<String, dynamic>> _payments =
      FirebaseFirestore.instance.collection(FirestorePaths.payments);

  Stream<List<PaymentModel>> streamAllPayments() {
    return _payments.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => PaymentModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<PaymentModel>> streamPaymentsForMember(String memberId) {
    return _payments
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => PaymentModel.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.paidDate.compareTo(a.paidDate));
      return list;
    });
  }

  Future<void> recordPayment(PaymentModel payment) {
    return _payments.doc(payment.id).set(payment.toMap());
  }
}
