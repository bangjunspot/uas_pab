import 'package:flutter/material.dart';
import '../theme/clay_colors.dart';
import '../theme/clay_shadows.dart';

class ClayFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const ClayFab({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ClayColors.primary, ClayColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: ClayShadows.button,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
