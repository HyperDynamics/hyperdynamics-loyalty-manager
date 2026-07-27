import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Controlled text input matching the design system's `Input` component:
/// label above, optional prefix glyph/currency symbol, helper text or
/// persistent inline error below, password show/hide toggle.
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.label,
    this.placeholder,
    required this.value,
    required this.onChanged,
    this.error,
    this.hint,
    this.prefixText,
    this.obscureText = false,
    this.numeric = false,
    this.maxLength,
    this.autofocus = false,
    this.enabled = true,
    this.onSubmitted,
  });

  final String? label;
  final String? placeholder;
  final String value;
  final ValueChanged<String> onChanged;
  final String? error;
  final String? hint;
  final String? prefixText;
  final bool obscureText;
  final bool numeric;
  final int? maxLength;
  final bool autofocus;
  final bool enabled;
  final VoidCallback? onSubmitted;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final TextEditingController _controller;
  late bool _obscured;
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _obscured = widget.obscureText;
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void didUpdateWidget(covariant AppInput old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final borderColor = hasError
        ? AppColors.loss
        : _focused
            ? AppColors.mint500
            : AppColors.borderSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTypography.xs),
          const SizedBox(height: 8),
        ],
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceInput,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: _focused || hasError ? 1.5 : 1),
          ),
          child: Row(
            children: [
              if (widget.prefixText != null) ...[
                Text(
                  widget.prefixText!,
                  style: AppTypography.body.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  obscureText: _obscured,
                  onChanged: widget.onChanged,
                  onSubmitted: (_) => widget.onSubmitted?.call(),
                  maxLength: widget.maxLength,
                  keyboardType: widget.numeric ? TextInputType.number : TextInputType.text,
                  inputFormatters: widget.numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
                  style: AppTypography.body.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  cursorColor: AppColors.mint400,
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    border: InputBorder.none,
                    hintText: widget.placeholder,
                    hintStyle: AppTypography.body.copyWith(color: AppColors.textDisabled),
                  ),
                ),
              ),
              if (widget.obscureText)
                GestureDetector(
                  onTap: () => setState(() => _obscured = !_obscured),
                  child: Text(
                    _obscured ? 'show' : 'hide',
                    style: AppTypography.xs.copyWith(color: AppColors.mint400),
                  ),
                ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(widget.error!, style: AppTypography.xs2.copyWith(color: AppColors.loss)),
        ] else if (widget.hint != null) ...[
          const SizedBox(height: 6),
          Text(widget.hint!, style: AppTypography.xs2),
        ],
      ],
    );
  }
}
