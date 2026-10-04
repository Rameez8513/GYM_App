import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../models/member_model.dart';
import '../models/payment_model.dart';

class MemberService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _members =>
      _db.collection(FirestorePaths.members);
  CollectionReference<Map<String, dynamic>> get _payments =>
      _db.collection(FirestorePaths.payments);

  Stream<List<MemberModel>> streamMembers() {
    return _members.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => MemberModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<MemberModel?> streamMember(String memberId) {
    return _members.doc(memberId).snapshots().map(
          (doc) => doc.exists ? MemberModel.fromMap(doc.id, doc.data()!) : null,
        );
  }

  Future<void> addMemberWithPayment(MemberModel member, PaymentModel? payment) {
    final batch = _db.batch();
    batch.set(_members.doc(member.id), member.toMap());
    if (payment != null) {
      batch.set(_payments.doc(payment.id), payment.toMap());
    }
    return batch.commit();
  }

  Future<void> updateMember(MemberModel member) {
    return _members.doc(member.id).update(member.toMap());
  }

  Future<void> setActiveStatus(String memberId, bool isActive) {
    return _members
        .doc(memberId)
        .update({'status': isActive ? 'active' : 'inactive'});
  }

  Future<void> deleteMember(String memberId) {
    return _members.doc(memberId).delete();
  }

  Future<void> recordPaid(
      String memberId, PaymentModel payment, DateTime newDueDate) {
    final batch = _db.batch();
    batch.update(_members.doc(memberId), {
      'currentMonthPaid': true,
      'nextDueDate': Timestamp.fromDate(newDueDate),
    });
    batch.set(_payments.doc(payment.id), payment.toMap());
    return batch.commit();
  }

  Future<void> markPaymentStatus({
    required String memberId,
    required bool paid,
    DateTime? newDueDate,
    PaymentModel? unpaidLog,
  }) {
    final batch = _db.batch();
    final data = <String, dynamic>{'currentMonthPaid': paid};
    if (newDueDate != null) {
      data['nextDueDate'] = Timestamp.fromDate(newDueDate);
    }
    batch.update(_members.doc(memberId), data);
    if (unpaidLog != null) {
      batch.set(_payments.doc(unpaidLog.id), unpaidLog.toMap());
    }
    return batch.commit();
  }
}
