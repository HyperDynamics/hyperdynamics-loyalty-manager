import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feedback_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Fixed-position toast rendered above whatever screen is on top —
/// mount once near the root of the app (both pre-auth and authed shells).
class ToastHost extends ConsumerWidget {
  const ToastHost({super.key, this.bottomOffset = 28});

  final double bottomOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider);
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedSwitcher(
          duration: AppDurations.quick,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: toast == null
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : Padding(
                  key: ValueKey(toast.message),
                  padding: EdgeInsets.only(bottom: bottomOffset),
                  child: _ToastBubble(toast: toast),
                ),
        ),
      ),
    );
  }
}

class _ToastBubble extends StatelessWidget {
  const _ToastBubble({required this.toast});
  final ToastMessage toast;

  @override
  Widget build(BuildContext context) {
    final (border, icon, iconColor) = switch (toast.tone) {
      ToastTone.success => (AppColors.mint500, Icons.check_circle, AppColors.mint400),
      ToastTone.error => (AppColors.loss, Icons.error, AppColors.loss),
      ToastTone.info => (AppColors.borderStrong, Icons.info, AppColors.info),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElev,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: border),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Flexible(
              child: Text(toast.message, style: AppTypography.sm.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              )),
            ),
          ],
        ),
      ),
    );
  }
}
