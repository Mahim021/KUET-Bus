import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Reusable themed text field for all auth screens — responds to dark mode.
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
    final theme = AppThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: theme.label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: theme.fieldFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.border),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscure : false,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: TextStyle(fontSize: 15, color: theme.text),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: theme.subText, fontSize: 15),
              prefixIcon:
                  Icon(widget.icon, color: theme.subText, size: 20),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: theme.subText,
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
