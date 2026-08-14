import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ledger_repository.dart';
import '../models/customer.dart';
import '../models/loyalty_transaction.dart';
import '../models/sales_summary.dart';
import 'auth_providers.dart';
import 'business_providers.dart';
import 'repository_providers.dart';

String? _businessId(Ref ref) => ref.watch(authSessionProvider).value?.businessId;

final businessStatsProvider = StreamProvider<BusinessStats>((ref) {
  final businessId = _businessId(ref);
  if (businessId == null) return Stream.value(const BusinessStats(todayEarnCount: 0, todayRedeemCount: 0, pointsOutstanding: 0));
  return ref.watch(ledgerRepositoryProvider).watchStats(businessId);
});

final recentTransactionsProvider = StreamProvider<List<LoyaltyTransaction>>((ref) {
  final businessId = _businessId(ref);
  if (businessId == null) return Stream.value(const []);
  return ref.watch(ledgerRepositoryProvider).watchRecentTransactions(businessId);
});

final customersListProvider = StreamProvider.family<List<Customer>, bool>((ref, descending) {
  final businessId = _businessId(ref);
  if (businessId == null) return Stream.value(const []);
  return ref.watch(ledgerRepositoryProvider).watchCustomers(businessId, descending: descending);
});

/// Birthdays inside the business's configured window (today + next N-1 days,
/// owner-set in Settings). Watches `currentBusinessProvider` so changing the
/// window in Settings re-runs the query immediately.
final upcomingBirthdaysProvider = StreamProvider<List<Customer>>((ref) {
  final businessId = _businessId(ref);
  if (businessId == null) return Stream.value(const []);
  final windowDays = ref.watch(currentBusinessProvider).value?.birthdayWindowDays ?? 1;
  return ref.watch(ledgerRepositoryProvider).watchUpcomingBirthdays(businessId, windowDays: windowDays);
});

typedef DateRange = ({DateTime start, DateTime end});

final salesSummaryProvider = FutureProvider.family<SalesSummary, DateRange>((ref, range) {
  final businessId = _businessId(ref);
  if (businessId == null) return Future.value(SalesSummary.zero);
  return ref.watch(ledgerRepositoryProvider).fetchSalesSummary(businessId, start: range.start, end: range.end);
});

final customerWatchProvider = StreamProvider.family<Customer?, String>((ref, phone) {
  final businessId = _businessId(ref);
  if (businessId == null || phone.isEmpty) return Stream.value(null);
  return ref.watch(ledgerRepositoryProvider).watchCustomer(businessId, phone);
});

final customerHistoryProvider = StreamProvider.family<List<LoyaltyTransaction>, String>((ref, phone) {
  final businessId = _businessId(ref);
  if (businessId == null || phone.isEmpty) return Stream.value(const []);
  return ref.watch(ledgerRepositoryProvider).watchCustomerHistory(businessId, phone);
});

final correctionFeedProvider = StreamProvider.family<List<LoyaltyTransaction>, String>((ref, phoneFilter) {
  final businessId = _businessId(ref);
  if (businessId == null) return Stream.value(const []);
  return ref.watch(ledgerRepositoryProvider).watchCorrectionFeed(businessId, phoneFilter: phoneFilter);
});
