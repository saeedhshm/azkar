/// Design Tokens — Border Radius System
/// استخدم هذه القيم دائماً بدلاً من الأرقام الثابتة
class AppRadius {
  AppRadius._();

  /// 6px — radius صغير جداً (chips, badges)
  static const double xs = 6;

  /// 10px — radius صغير (inputs, small cards)
  static const double sm = 10;

  /// 16px — radius متوسط (cards, dialogs)
  static const double md = 16;

  /// 20px — radius كبير (hero cards)
  static const double lg = 20;

  /// 24px — radius كبير جداً (sheets, panels)
  static const double xl = 24;

  /// 28px — radius ضخم (navigation bar, big cards)
  static const double xxl = 28;

  /// 999px — دائري كامل (pills, avatars, FABs)
  static const double pill = 999;
}
