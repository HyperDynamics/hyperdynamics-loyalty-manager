import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../providers/business_providers.dart';
import '../providers/feedback_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import 'app_button.dart';

/// Shared WhatsApp click-to-chat dialog — pending-points nudges
/// (`CustomerListScreen`) and birthday wishes (`BirthdayScreen`) both use
/// this, differing only in [title] and the pre-filled [buildMessage].
/// Presented via `showAppNudgeDialog` below, matching `showAppConfirmDialog`'s
/// centered, width-constrained `Dialog` pattern rather than a full-height
/// bottom sheet — a 4-line message and two buttons don't need to claim most
/// of the viewport.
Future<void> showAppNudgeDialog(
  BuildContext context, {
  required Customer customer,
  required String title,
  required String Function(Customer customer, String businessName) buildMessage,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    builder: (context) => Dialog(
      backgroundColor: AppColors.surfaceElev,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440, maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          child: _NudgeContent(customer: customer, title: title, buildMessage: buildMessage),
        ),
      ),
    ),
  );
}

class _NudgeContent extends ConsumerStatefulWidget {
  const _NudgeContent({required this.customer, required this.title, required this.buildMessage});

  final Customer customer;
  final String title;
  final String Function(Customer customer, String businessName) buildMessage;

  @override
  ConsumerState<_NudgeContent> createState() => _NudgeContentState();
}

class _NudgeContentState extends ConsumerState<_NudgeContent> {
  late String _message;

  @override
  void initState() {
    super.initState();
    final businessName = ref.read(currentBusinessProvider).value?.displayName ?? 'us';
    _message = widget.buildMessage(widget.customer, businessName);
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _message));
    if (mounted) {
      ref.read(toastProvider.notifier).show('message copied.', ToastTone.success);
    }
  }

  Future<void> _openWhatsapp() async {
    final phone = digitsOnly(widget.customer.phone);
    final uri = Uri.parse('https://wa.me/91$phone?text=${Uri.encodeComponent(_message)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ref.read(toastProvider.notifier).show('could not open whatsapp.', ToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: AppTypography.xs.copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text(widget.customer.name, style: AppTypography.h3),
          Text(maskPhone(widget.customer.phone), style: AppTypography.xs2),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceInput,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: TextField(
              controller: TextEditingController(text: _message)..selection = TextSelection.collapsed(offset: _message.length),
              onChanged: (v) => _message = v,
              maxLines: 4,
              style: AppTypography.body.copyWith(fontSize: 14),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AppButton(label: 'copy message', variant: AppButtonVariant.outline, onPressed: _copy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(label: 'open whatsapp', icon: Icons.chat_bubble_outline_rounded, onPressed: _openWhatsapp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
