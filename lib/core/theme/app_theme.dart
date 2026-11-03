import 'package:flutter/material.dart';

class AppTheme {
  static const _defaultSeedColor = Colors.indigo;

  static ThemeData light({Color seedColor = _defaultSeedColor}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData dark({Color seedColor = _defaultSeedColor}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
    );
  }

  /// アプリアイコンの色（背景の紺はスプラッシュ画面の背景 `pubspec.yaml` の flutter_native_splash.color と同じ）
  static const brandNavy = Color(0xFF15203B);
  static const brandYellow = Color(0xFFFFD43F);
  static const brandLightBlue = Color(0xFF8099EB);

  /// 紺の背景の上のリンクの色（読みやすさを優先して白。リンクであることは下線で示す）
  static const brandLink = Colors.white;

  /// ログイン画面など、ログイン前の画面のテーマ。スプラッシュ画面から見た目がつながるように、
  /// アイコンと同じ紺の背景にする（ユーザーの色・ダークモードの設定はログイン後の画面にだけ使う）
  static ThemeData brand() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandLightBlue,
      brightness: Brightness.dark,
    ).copyWith(
      surface: brandNavy,
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFC5CBDD),
      outline: const Color(0xFF6B7697),
      primary: brandYellow,
      onPrimary: brandNavy,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brandNavy,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: brandLink),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
    );
  }

  static const Map<String, Color> colorThemes = {
    'indigo': Colors.indigo,
    'blue': Colors.blue,
    'teal': Colors.teal,
    'green': Colors.green,
    'orange': Colors.orange,
    'pink': Colors.pink,
    'purple': Colors.purple,
  };
}
