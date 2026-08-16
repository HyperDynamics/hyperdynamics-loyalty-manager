import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/staff_member.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

/// The current business's staff roster — live, so a seat freed up by removing
/// one staff member is immediately reflected in the "add staff" form's cap
/// check without needing a manual refresh.
final businessStaffProvider = StreamProvider<List<StaffMember>>((ref) {
  final businessId = ref.watch(authSessionProvider).value?.businessId;
  if (businessId == null) return Stream.value(const []);
  return ref.watch(staffRepositoryProvider).watchStaff(businessId);
});
