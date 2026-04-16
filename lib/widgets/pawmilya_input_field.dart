import 'package:flutter/material.dart';

import '../theme/pawmilya_palette.dart';

class PawmilyaInputField extends StatelessWidget {
  const PawmilyaInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.playful,
    this.keyboardType,
    this.obscureText = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool playful;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final radius = playful ? 22.0 : 18.0;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: PawmilyaPalette.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: PawmilyaPalette.textSecondary.withValues(alpha: 0.75),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: playful ? 0.93 : 0.97),
        prefixIcon: Icon(
          icon,
          color: playful
              ? PawmilyaPalette.goldDark
              : PawmilyaPalette.shelterBrown,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: PawmilyaPalette.cardEdge.withValues(alpha: 0.85),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(
            color: PawmilyaPalette.goldDark,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
