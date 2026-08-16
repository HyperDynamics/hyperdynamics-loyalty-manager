import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/staff_member.dart';

class StaffFailure implements Exception {
  const StaffFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Owner-side staff management — add/remove your own business's staff,
/// capped at `Business.maxStaffSeats`. Mutations go through Cloud Functions
/// (`ownerCreateStaff`/`ownerRemoveStaff`, both re-check the caller is the
/// owner server-side); the roster itself is read straight from Firestore,
/// since the business's own staff subcollection is already client-readable
/// per firestore.rules — no need for a callable just to list it.
class StaffRepository {
  StaffRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<StaffMember>> watchStaff(String businessId) => _db
      .collection('businesses')
      .doc(businessId)
      .collection('staff')
      .orderBy('createdAt')
      .snapshots()
      .map((q) => q.docs.map((d) => StaffMember.fromDoc(d.id, d.data())).toList());

  Future<StaffMember> createStaff({required String email, String? displayName}) async {
    try {
      final res = await _functions.httpsCallable('ownerCreateStaff').call<Map<Object?, Object?>>({
        'email': email,
        'displayName': ?displayName,
      });
      return StaffMember.fromMap(res.data.cast<String, dynamic>());
    } on FirebaseFunctionsException catch (e) {
      throw StaffFailure(e.message ?? 'could not add staff. please try again.');
    }
  }

  Future<void> removeStaff(String uid) async {
    try {
      await _functions.httpsCallable('ownerRemoveStaff').call<Map<String, dynamic>>({'uid': uid});
    } on FirebaseFunctionsException catch (e) {
      throw StaffFailure(e.message ?? 'could not remove staff. please try again.');
    }
  }
}
