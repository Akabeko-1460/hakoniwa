// デザイントークン（design_handoff_hakoniwa/README.md セクション3）
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const accent = Color(0xFFE08A63); // アクセント（メイン・オレンジ）
  static const accentDark = Color(0xFFC25E3A); // アクセント濃（テキスト・押下）
  static const accentRec = Color(0xFFC2452F); // 録音中
  static const accentPale = Color(0xFFFBEDE4); // アクセント淡背景
  static const green = Color(0xFF8BA36F); // サブ（グリーン・みお/完了）
  static const greenPale = Color(0xFFEEF2E6);
  static const greenDark = Color(0xFF5E7345);
  static const greenBorder = Color(0xFFCBDAB6);
  static const yellow = Color(0xFFC6A05E); // サブ（イエロー）
  static const blue = Color(0xFF7FA6C4); // 追加ピン（ブルー・つみき）
  static const textStrong = Color(0xFF4A3728);
  static const textMid = Color(0xFF5C4A38);
  static const textMid2 = Color(0xFF7A6650);
  static const textFaint = Color(0xFF8B7355);
  static const textFaint2 = Color(0xFFA18A72);
  static const textFaint3 = Color(0xFFB7A488);
  static const textFaint4 = Color(0xFFC6B79E);
  static const cream = Color(0xFFFBF6EE); // 背景・クリーム（画面）
  static const spaceBg = Color(0xFFF3EAD9); // 背景・ハコニワ画面
  static const spaceGradTop = Color(0xFFEBDFC8);
  static const card = Color(0xFFFFFFFF);
  static const shadowBase = Color(0xFF785537); // rgb(120,85,55)
  static const underline = Color(0xFFEADFCC);
  static const divider = Color(0xFFF1E9DA);
  static const chipBg = Color(0xFFF0E7D7);
  static const woodLight = Color(0xFFCBA271);
  static const woodDark = Color(0xFFA97C4E);
  static const trackBg = Color(0xFFEEE4D3);
  static const toggleOff = Color(0xFFE4D8C2);
  static const phText = Color(0xFFB3A188);
  static const phStripeA = Color(0xFFE9DECC);
  static const phStripeB = Color(0xFFF2EADA);
  static const onboardTop = Color(0xFFF6EEDF);
  static const onboardBottom = Color(0xFFEBDCC3);
  static const waveA = Color(0xFFE7C4AE);
  static const waveB = Color(0xFFEBDCC6);
  static const knob = Color(0xFFE7DAC4);
  static const addTint = Color(0xFFC29A72);

  static Color border(double opacity) => shadowBase.withValues(alpha: opacity);
}

/// 書体の解決口。既定では google_fonts が Google Fonts から取ってくる。
///
/// フォントを端末に同梱する構成に変えるときや、通信させたくないテストでは
/// ここを差し替えれば、呼び出し側（AppFonts）はそのままで済む。
typedef FontResolver = TextStyle Function({required bool maru, required TextStyle base});

TextStyle _googleFonts({required bool maru, required TextStyle base}) => maru
    ? GoogleFonts.zenMaruGothic(textStyle: base)
    : GoogleFonts.zenKakuGothicNew(textStyle: base);

FontResolver fontResolver = _googleFonts;

/// 見出し・タイトル・数字・ボタン = Zen Maru Gothic
/// 本文・ラベル・メモ = Zen Kaku Gothic New
abstract final class AppFonts {
  static TextStyle maru(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textStrong,
    double? height,
  }) => fontResolver(
    maru: true,
    base: TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    ),
  );

  static TextStyle kaku(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textMid,
    double? height,
  }) => fontResolver(
    maru: false,
    base: TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    ),
  );
}

abstract final class AppShadows {
  /// 影のトークン。RN 版 theme.ts の `shadow()` と同じ引き数の並び。
  static BoxShadow of(
    double opacity,
    double blur,
    double offsetY, [
    Color color = AppColors.shadowBase,
  ]) => BoxShadow(
    color: color.withValues(alpha: opacity),
    blurRadius: blur,
    offset: Offset(0, offsetY),
  );

  static final card = [of(0.10, 20, 8)]; // カード
  static final cardSoft = [of(0.08, 16, 6)];
  static final button = [of(0.32, 18, 8, AppColors.accent)]; // ボタン
  static final frame = [of(0.30, 38, 20)]; // 木枠
  static final sheet = [of(0.16, 26, -2)];
}

abstract final class AppRadii {
  static const card = BorderRadius.all(Radius.circular(22));
  static const mid = BorderRadius.all(Radius.circular(18));
  static const small = BorderRadius.all(Radius.circular(14));
  static const button = BorderRadius.all(Radius.circular(16));
  static const pill = BorderRadius.all(Radius.circular(999));
}

/// 画面の左右パディングは 20px（デザイン基準）
const double kScreenPadding = 20;

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: AppFonts.kaku(14).fontFamily,
      bodyColor: AppColors.textStrong,
      displayColor: AppColors.textStrong,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

/// `#RRGGBB` 文字列を Color に。テーマカラーはデータとして文字列で持っている。
Color hexColor(String hex) {
  final v = hex.replaceFirst('#', '');
  return Color(int.parse(v.length == 6 ? 'FF$v' : v, radix: 16));
}

/// デザイン基準: 上 padding 56px（ステータスバー分）/ 下 26px（ホームインジケータ分）
/// 実デバイスでは safe-area に合わせて可変にする
({double top, double bottom}) screenInsets(BuildContext context) {
  final insets = MediaQuery.viewPaddingOf(context);
  return (
    top: insets.top + 12 < 56 ? 56 : insets.top + 12,
    bottom: insets.bottom + 9 < 26 ? 26 : insets.bottom + 9,
  );
}
