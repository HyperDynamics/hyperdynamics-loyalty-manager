import 'package:cloud_firestore/cloud_firestore.dart';

/// One staff account on a business. Self-serve, added and removed by the
/// business owner in Settings (see `functions/src/staff.ts`'s `ownerCreateStaff`/
/// `ownerRemoveStaff`) — capped at `Business.maxStaffSeats`. Signs in with
/// Google only, hence the mandatory gmail address.
class StaffMember {
  const StaffMember({
    required this.uid,
    required this.email,
    required this.displayName,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final DateTime? createdAt;

  /// What to show in a list row: the entered name if there is one, otherwise
  /// the local part of the gmail address.
  String get label => displayName.trim().isNotEmpty ? displayName.trim() : email.split('@').first;

  /// From the operator console's `adminListStaff` callable, which returns
  /// `createdAtMs` (plain JSON has no Timestamp type).
  factory StaffMember.fromMap(Map<String, dynamic> map) => StaffMember(
        uid: (map['uid'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
        displayName: (map['displayName'] as String?) ?? '',
        createdAt: (map['createdAtMs'] as num?) != null
            ? DateTime.fromMillisecondsSinceEpoch((map['createdAtMs'] as num).toInt())
            : null,
      );

  /// From the owner's direct Firestore stream of `businesses/{id}/staff` — the
  /// business's own subcollection, client-readable per firestore.rules — where
  /// `createdAt` is a native `Timestamp`, not millis.
  factory StaffMember.fromDoc(String uid, Map<String, dynamic> data) => StaffMember(
        uid: uid,
        email: (data['email'] as String?) ?? '',
        displayName: (data['displayName'] as String?) ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
}
