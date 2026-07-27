import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/business_repository.dart';
import '../data/ledger_repository.dart';
import '../data/payment_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final businessRepositoryProvider = Provider<BusinessRepository>((ref) => BusinessRepository());
final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) => LedgerRepository());
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) => PaymentRepository());
