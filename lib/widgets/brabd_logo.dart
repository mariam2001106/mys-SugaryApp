import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 96, // total diameter in logical pixels
    this.assetPath = 'assets/images/logo.png',
  });

  final double size;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface, // white (light) / surface (dark)
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(
        size * 0.12,
      ), // inner padding so the image breathes
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover, // crop to circle nicely
        ),
      ),
    );
  }
}
