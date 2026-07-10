import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF6F2DBD);
  static const Color deepPurple = Color(0xFF4C1D95);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentAmber = Color(0xFFFFC107);

  static ThemeData light() {
    final base = ThemeData.dark();
    return base.copyWith(
      brightness: Brightness.dark,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: const Color(0xFF200F46),
      colorScheme: ColorScheme.fromSeed(seedColor: primaryPurple),
      textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
      // styles to use on light surfaces (cards, inputs)
      extensions: <ThemeExtension<dynamic>>[
        LightTextStyles(
          body: GoogleFonts.poppins(color: Colors.black87),
          subtitle: GoogleFonts.poppins(color: Colors.black54),
        ),
      ],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentAmber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: deepPurple, elevation: 0, centerTitle: true),
    );
  }
}

class LightTextStyles extends ThemeExtension<LightTextStyles> {
  final TextStyle? body;
  final TextStyle? subtitle;

  const LightTextStyles({this.body, this.subtitle});

  @override
  LightTextStyles copyWith({TextStyle? body, TextStyle? subtitle}) => LightTextStyles(body: body ?? this.body, subtitle: subtitle ?? this.subtitle);

  @override
  LightTextStyles lerp(ThemeExtension<LightTextStyles>? other, double t) {
    if (other is! LightTextStyles) return this;
    return LightTextStyles(body: TextStyle.lerp(body, other.body, t), subtitle: TextStyle.lerp(subtitle, other.subtitle, t));
  }
}

