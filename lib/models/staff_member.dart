/// One staff account on a business. Created only by the HyperDynamics operator
/// in `/hd-ops` (see `functions/src/staff.ts`) — businesses can't self-serve
/// seats — and signs in with Google only, hence the mandatory gmail address.
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

  /// What to show in a list row: the operator-entered name if there is one,
  /// otherwise the local part of the gmail address.
  String get label => displayName.trim().isNotEmpty ? displayName.trim() : email.split('@').first;

  factory StaffMember.fromMap(Map<String, dynamic> map) => StaffMember(
        uid: (map['uid'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
        displayName: (map['displayName'] as String?) ?? '',
        createdAt: (map['createdAtMs'] as num?) != null
            ? DateTime.fromMillisecondsSinceEpoch((map['createdAtMs'] as num).toInt())
            : null,
      );
}
