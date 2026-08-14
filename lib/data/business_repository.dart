import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/business.dart';

/// Business profile is simple enough to be a direct, security-rule-guarded
/// client write (unlike balance-mutating collections, which route through
/// Cloud Functions) — see firestore.rules for the field allow-list.
class BusinessRepository {
  BusinessRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _doc(String businessId) =>
      _db.collection('businesses').doc(businessId);

  Stream<Business?> watch(String businessId) => _doc(businessId).snapshots().map(
        (snap) => snap.exists ? Business.fromMap(snap.id, snap.data()!) : null,
      );

  Future<void> updateProfile(
    String businessId, {
    String? displayName,
    int? pointsRatio,
    String? logoUrl,
  }) {
    final data = <String, dynamic>{
      'displayName': ?displayName,
      'pointsRatio': ?pointsRatio,
      'logoUrl': ?logoUrl,
    };
    if (data.isEmpty) return Future.value();
    return _doc(businessId).update(data);
  }

  Future<void> setOtpEnabled(String businessId, bool enabled) =>
      _doc(businessId).update({'otpEnabled': enabled});

  /// Owner-only operational switches. Rule-guarded to owners (`isOwner` in
  /// firestore.rules) and re-checked server-side in `earn.ts` — a staff account
  /// reaching this would be rejected by rules, not just hidden in the UI.
  Future<void> updateOperations(
    String businessId, {
    bool? billNumberRequired,
    bool? manualPointsEnabled,
    int? birthdayWindowDays,
  }) {
    final data = <String, dynamic>{
      'billNumberRequired': ?billNumberRequired,
      'manualPointsEnabled': ?manualPointsEnabled,
      'birthdayWindowDays': ?birthdayWindowDays?.clamp(1, 10),
    };
    if (data.isEmpty) return Future.value();
    return _doc(businessId).update(data);
  }

  Future<void> updateStaffPermissions(String businessId, StaffPermissions permissions) =>
      _doc(businessId).update({'staffPermissions': permissions.toMap()});

  Future<void> setGateway(String businessId, OtpGateway gateway) =>
      _doc(businessId).update({'gateway': gateway == OtpGateway.byo ? 'byo' : 'managed'});

  /// BYO gateway credentials are written to the Cloud-Functions-only
  /// `private/otpGateway` subdocument (see firestore.rules) via a callable,
  /// not a direct client write — kept out of this repo, see LedgerRepository.

  Future<String> uploadLogo(String businessId, Uint8List bytes, {required String contentType}) async {
    final ext = contentType == 'image/svg+xml' ? 'svg' : 'png';
    final ref = _storage.ref('businesses/$businessId/logo.$ext');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
