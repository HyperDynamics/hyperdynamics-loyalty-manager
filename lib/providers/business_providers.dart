import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

/// Live business profile for the signed-in admin's business.
final currentBusinessProvider = StreamProvider<Business?>((ref) {
  final session = ref.watch(authSessionProvider).value;
  if (session == null) return Stream.value(null);
  return ref.watch(businessRepositoryProvider).watch(session.businessId);
});
