import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
//  LOKSEVA · AppColors — 2026 Design System
//  Umang-inspired: Professional Light Government Theme
//  Palette: Clean White · Deep Government Blue · Tricolour Accents
//  WCAG 2.1 AA compliant contrast ratios throughout
// ═══════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Brand Core ────────────────────────────────────────────────────
  /// Deep Government Blue — primary actions, headers, nav
  static const Color primary      = Color(0xFF003580);
  static const Color primaryLight = Color(0xFF1A5DB5);
  static const Color primaryDark  = Color(0xFF002060);

  /// Teal/Cyan — secondary actions, chips
  static const Color secondary      = Color(0xFF0096C7);
  static const Color secondaryLight = Color(0xFF48CAE4);
  static const Color secondaryDark  = Color(0xFF005F7A);

  /// Saffron Orange — CTA highlights, badges, accents
  static const Color accent      = Color(0xFFFF6B00);
  static const Color accentLight = Color(0xFFFF9A3C);
  static const Color accentDark  = Color(0xFFCC5500);

  // ── Semantic ──────────────────────────────────────────────────────
  static const Color warning    = Color(0xFFFF8C00);
  static const Color warningBg  = Color(0xFFFFF3E0);
  static const Color warning2   = Color(0xFFFF6B35);  // Added for notification_model
  static const Color success    = Color(0xFF1B8B34);
  static const Color successBg  = Color(0xFFE8F5E9);
  static const Color error      = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info       = Color(0xFF0277BD);
  static const Color infoBg     = Color(0xFFE1F5FE);

  // ── Indian Tricolour Accents ──────────────────────────────────────
  static const Color saffron    = Color(0xFFFF9933);
  static const Color triWhite   = Color(0xFFFFFFFF);
  static const Color triGreen   = Color(0xFF138808);
  static const Color ashokaBlue = Color(0xFF000080);

  // ── Surface / Background (Light Theme) ───────────────────────────
  static const Color bgPage      = Color(0xFFF4F6FA);   // page background
  static const Color bgCard      = Color(0xFFFFFFFF);   // cards
  static const Color bgSurface   = Color(0xFFF0F2F8);   // input fields
  static const Color bgSection   = Color(0xFFE8ECF4);   // section bg
  static const Color bgDeep      = Color(0xFF0A1628);   // Deep dark blue for splash screen
  static const Color surface      = Color(0xFF1A2538);  // Surface color for dialogs
  
  // Glass effects (semi-transparent backgrounds)
  static const Color glass05     = Color(0x0DFFFFFF);  // 5% white opacity
  static const Color glass08     = Color(0x14FFFFFF);  // 8% white opacity
  
  // Border colors
  static const Color borderSubtle = Color(0x1AFFFFFF); // Subtle white border (10% opacity)

  /// Header gradient backgrounds
  static const Color headerTop    = Color(0xFF003580);
  static const Color headerBottom = Color(0xFF0055B3);

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0D1B36);  // near-black
  static const Color textSecondary = Color(0xFF4A5568);  // medium grey
  static const Color textTertiary  = Color(0xFF718096);  // light grey
  static const Color textDisabled  = Color(0xFFA0AEC0);
  static const Color textOnDark    = Color(0xFFFFFFFF);
  static const Color textOnDarkSub = Color(0xFFB8D0F0);  // faded on blue

  // ── Grey Scale ────────────────────────────────────────────────────
  static const Color white   = Color(0xFFFFFFFF);
  static const Color black   = Color(0xFF000000);
  static const Color grey50  = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = Color(0xFF0F172A);

  // ── Border / Divider ──────────────────────────────────────────────
  static const Color borderLight   = Color(0xFFE2E8F0);
  static const Color borderDefault = Color(0xFFCBD5E1);
  static const Color borderFocus   = Color(0xFF003580);

  // ── Transparent ───────────────────────────────────────────────────
  static const Color transparent = Color(0x00000000);

  // ═══════════════════════════════════════════════════════════════════
  //  Gradients
  // ═══════════════════════════════════════════════════════════════════

  /// Background gradient for splash screen
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF132440), Color(0xFF0D1B2A)],
  );

  /// Logo gradient for splash screen
  static const RadialGradient logoGradient = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [Color(0xFF003580), Color(0xFF002060), Color(0xFF001540)],
  );

  /// Header / SliverAppBar gradient (deep-to-mid government blue)
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF002060), Color(0xFF003580), Color(0xFF0055B3)],
  );

  /// CTA button gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF003580), Color(0xFF0055B3)],
  );

  /// Saffron accent gradient (for icon backgrounds, tags)
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B00), Color(0xFFFF9933)],
  );

  /// Tricolour top bar
  static const LinearGradient tricolourGradient = LinearGradient(
    colors: [
      Colors.transparent,
      Color(0xFFFF9933),
      Color(0xFFFFFFFF),
      Color(0xFF138808),
      Colors.transparent,
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  /// Login/Register header gradient
  static const LinearGradient loginHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF002060), Color(0xFF003580)],
  );

  // ═══════════════════════════════════════════════════════════════════
  //  Dynamic Gradients (methods)
  // ═══════════════════════════════════════════════════════════════════

  /// Shimmer gradient for text animation
  static LinearGradient shimmerGradient(double shimmerValue) {
    return LinearGradient(
      begin: Alignment(-1.5 + shimmerValue, 0),
      end: Alignment(-0.5 + shimmerValue, 0),
      colors: const [
        Colors.white24,
        Colors.white70,
        Colors.white,
        Colors.white70,
        Colors.white24,
      ],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    );
  }

  /// Progress gradient for loading bar
  static LinearGradient progressGradient(double shimmerValue) {
    return LinearGradient(
      begin: Alignment(-1.5 + shimmerValue, 0),
      end: Alignment(-0.5 + shimmerValue, 0),
      colors: const [
        Color(0xFF003580),
        Color(0xFF0055B3),
        Color(0xFF0096C7),
        Color(0xFF0055B3),
        Color(0xFF003580),
      ],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Shadow helpers
  // ═══════════════════════════════════════════════════════════════════

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF003580).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> inputFocusShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════
  //  Utility
  // ═══════════════════════════════════════════════════════════════════

  static Color alpha(Color c, double opacity) =>
      c.withValues(alpha: opacity.clamp(0.0, 1.0));
}