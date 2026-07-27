import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feedback_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Full-screen dim + spinner shown while [busyProvider] is set —
/// mirrors the prototype's `this.withLoading(msg, fn)` overlay.
class LoadingOverlay extends ConsumerWidget {
  const LoadingOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(busyProvider);
    return Stack(
      children: [
        child,
        if (message != null)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.mint400),
                    ),
                    const SizedBox(height: 16),
                    Text(message, style: AppTypography.sm.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
