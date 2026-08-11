import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';
import '../data/auth_repository.dart';
import '../data/business_repository.dart';
import '../data/ledger_repository.dart';
import '../data/signup_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final businessRepositoryProvider = Provider<BusinessRepository>((ref) => BusinessRepository());
final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) => LedgerRepository());
final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository());
final signupRepositoryProvider = Provider<SignupRepository>((ref) => SignupRepository());
