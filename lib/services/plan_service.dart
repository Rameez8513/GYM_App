import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../models/plan_model.dart';

class PlanService {
  final CollectionReference<Map<String, dynamic>> _plans =
      FirebaseFirestore.instance.collection(FirestorePaths.plans);

  Stream<List<PlanModel>> streamPlans() {
    return _plans.orderBy('createdAt', descending: false).snapshots().map(
          (snap) =>
              snap.docs.map((d) => PlanModel.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addPlan(PlanModel plan) {
    return _plans.doc(plan.id).set(plan.toMap());
  }

  Future<void> updatePlan(PlanModel plan) {
    return _plans.doc(plan.id).update(plan.toMap());
  }

  Future<void> deletePlan(String planId) {
    return _plans.doc(planId).delete();
  }
}
