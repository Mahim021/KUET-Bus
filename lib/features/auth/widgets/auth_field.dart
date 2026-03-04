import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

/// Reusable themed text field for all auth screens.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.hint,
    required this.icon,
    this.label,
    this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.onChanged,
  });

  final String hint;
  final IconData icon;
  final String? label;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.fieldLabel),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscure : false,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: const TextStyle(fontSize: 15, color: AppColors.bodyText),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.fieldHint,
              prefixIcon: Icon(widget.icon, color: AppColors.fieldIcon, size: 20),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.fieldIcon,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
