// ============================================================
// PocketDay — PocketDayLogo
// ============================================================
//
// Purpose:
// Reusable brand logo component for rendering the official PocketDay visual identity.
//
// Responsibilities:
// - Render the official PocketDay logo asset ('assets/images/app_logo.png') with consistent aspect ratio.
// - Support standard size presets (small, medium, large) and explicit custom dimensions.
// - Support optional rounded container styling for splash and authentication hero screens.
//
// Data Flow:
// Asset Image ('assets/images/app_logo.png') → PocketDayLogo Widget → UI Screen Layout
//
// Main Operations:
// - build(context) — Renders the brand logo asset with configured dimensions and optional container styling.
//
// Dependencies / Collaborators:
// - Image.asset ('assets/images/app_logo.png') — Official high-resolution PocketDay logo asset.
//
// ============================================================

import 'package:flutter/material.dart';

enum PocketDayLogoSize { small, medium, large }

class PocketDayLogo extends StatelessWidget {
  final PocketDayLogoSize size;
  final double? customSize;
  final bool showBackground;

  const PocketDayLogo({
    super.key,
    this.size = PocketDayLogoSize.medium,
    this.customSize,
    this.showBackground = false,
  });

  double get _dimension {
    if (customSize != null) return customSize!;
    switch (size) {
      case PocketDayLogoSize.small:
        return 36.0;
      case PocketDayLogoSize.medium:
        return 64.0;
      case PocketDayLogoSize.large:
        return 96.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = _dimension;

    final imageWidget = Image.asset(
      'assets/images/app_logo.png',
      width: dim,
      height: dim,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.account_balance_wallet_rounded,
          size: dim,
          color: Theme.of(context).colorScheme.primary,
        );
      },
    );

    if (!showBackground) {
      return imageWidget;
    }

    return Container(
      padding: EdgeInsets.all(dim * 0.2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(25),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(60),
          width: 2,
        ),
      ),
      child: imageWidget,
    );
  }
}
