import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF000000); // Pure Black
  static const Color secondary = Color(0xFFFFFFFF); // Pure White
  static const Color tertiary = Color(0xFF1A1A1A); // Dark Grey

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color slate = Color(0xFF888888); // Medium Grey
  static const Color darkSlate = Color(0xFF333333); // Darker Grey
  
  // Background Colors
  static const Color backgroundDark = Color(0xFF050505); // Almost Black
  static const Color backgroundLight = Color(0xFFF5F5F5); // Off White
  
  // Surface Colors
  static const Color surfaceDark = Color(0xFF121212); // Material Dark Surface
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // Status Colors
  static const Color error = Color(0xFFCF6679);
  static const Color warning = Color(
    0xFFE0E0E0,
  ); // Light Grey for warning in monochrome theme
  static const Color success = Color(0xFFCCCCCC); // Light Grey for success

  // ── SDK brand colors ───────────────────────────────────────────────────────
  // Telling ships two SDKs for the same dashboard, so each gets a brand color
  // to mark which one a link, badge, or code sample belongs to. Everything
  // else in this app stays monochrome — these are the only brand hues.
  //
  // Flutter's pair was previously hardcoded at the badge in landing_screen.dart
  // (the only brand-color literals in the codebase); promoted here so the
  // landing page and the docs cannot drift apart.

  /// Flutter's brand blue. Used for the `telling_logger` badge and docs accent.
  static const Color flutterBlue = Color(0xFF02569B);

  /// Flutter's lighter brand blue, for icon and label on dark backgrounds.
  static const Color flutterBlueLight = Color(0xFF54C5F8);

  // DartNative's spectrum, sampled from its logo mark (dn-logo-transparent.svg).
  // It is a four-gradient spectrum rather than a single hue — pink through gold
  // and olive to cyan — so the badge renders a border sweep instead of a flat
  // color.
  static const Color dnGold = Color(0xFFF9D126); // primary
  static const Color dnPink = Color(0xFFFA60A6); // gradient head
  static const Color dnMagenta = Color(0xFFEF388B);
  static const Color dnSalmon = Color(0xFFE99173); // mid-warm
  static const Color dnOlive = Color(0xFFB5C75E); // gradient end
  static const Color dnTeal = Color(0xFF17C4E0);
  static const Color dnCyan = Color(0xFF03C3F0); // tail

  /// DartNative's full sweep, for badge borders and gradient text.
  static const LinearGradient dnSpectrum = LinearGradient(
    colors: <Color>[dnPink, dnMagenta, dnGold, dnOlive, dnCyan],
  );

  /// Sweep weighted toward gold, for the DartNative badge label where the
  /// full spectrum would be too faint at 13px.
  static const LinearGradient dnSpectrumLabel = LinearGradient(
    colors: <Color>[dnPink, dnGold, dnOlive, dnCyan],
  );
}
