library app_constants;

import 'package:flutter/material.dart';

class AnimationDurations {
  AnimationDurations._();

  static const Duration fast = Duration(milliseconds: 250);

  static const Duration standard = Duration(milliseconds: 380);

  static const Duration medium = Duration(milliseconds: 450);

  static const Duration slow = Duration(milliseconds: 600);

  static const Duration extraSlow = Duration(milliseconds: 1200);

  static const Duration continuous = Duration(seconds: 8);

  static const Duration loadingDelay = Duration(seconds: 2);
}

class AnimationCurves {
  AnimationCurves._();

  static const double opacityBlend = 0.72;

  static const double curveValueBlend = 0.28;

  static const double staggerDelayFactor = 0.1;

  static const double smoothEasing = 0.58;

  static const double parallaxX = 0.025;
}

class UIDimensions {
  UIDimensions._();

  static const double spacing = 8.0;

  static const double spacingSmall = spacing;

  static const double spacingMedium = spacing * 2;

  static const double spacingLarge = spacing * 3;

  static const double spacingExtraLarge = spacing * 4;

  static const double loginFormTopPadding = 22.0;

  static const double loginButtonHeight = 50.0;

  static const double loginCardBorderRadius = 12.0;

  static const double loginButtonWidthRatio = 0.06;
  static const double loginCardHeightRatio = 0.22;

  static const double cardElevation = 4.0;

  static const double cornerRadiusSmall = 8.0;

  static const double cornerRadiusStandard = 12.0;

  static const double cornerRadiusLarge = 16.0;
}

class CustomPainterDimensions {
  CustomPainterDimensions._();

  static const double leftCurveStart = 0.12;

  static const double leftCurveEnd = 0.76;

  static const double bookWidthRatio = 0.31;

  static const double bookHeightRatio = 0.45;

  static const double bookAccentWidthRatio = 0.06;

  static const double circleSegmentAngle = 0.08;

  static const double dotRadiusMultiplier = 0.012;

  static const double curveControlOffset = 0.18;

  static const double bookTopPaddingRatio = 0.12;

  static const double bookRightPaddingRatio = 0.16;
}

class ColorValues {
  ColorValues._();

  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  static const Color secondary = Color(0xFF64748B);
  static const Color secondaryLight = Color(0xFF94A3B8);
  static const Color secondaryDark = Color(0xFF475569);

  static const Color accent = Color(0xFF10B981);
  static const Color accentLight = Color(0x3310B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF0F1F3);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFFD1D5DB);

  static const Color statCardBackground = Color(0xFFEEF2FF);
  static const Color navigationBackground = Color(0xFFFFFFFF);
  static const Color appBarBackground = Color(0xFFFAFAFA);

  static const List<Color> primaryGradient = [primary, primaryLight];
  static const List<Color> successGradient = [
    Color(0xFF10B981),
    Color(0xFF059669)
  ];
  static const List<Color> warningGradient = [
    Color(0xFFF59E0B),
    Color(0xFFFDD503)
  ];

  static const int statCardBackgroundColor = 0xFFEEF2FF;
}

class AppConfig {
  AppConfig._();

  static const int defaultScholarshipDeadlineDays = 30;

  static const double defaultGwaThreshold = 2.0;

  static const double defaultMaxIncome = 30000.0;

  static const String defaultProviderName = 'Scholarship Provider';

  static const String defaultApplicationUrl = 'https://www.gov.ph/';

  static const List<String> defaultRequirements = [
    'Latest grades',
    'Certificate of enrollment',
    'Valid ID',
  ];

  static const List<int> availableYearLevels = [1, 2, 3, 4];
}
