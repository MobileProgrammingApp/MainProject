import 'package:flutter/material.dart';
import '../app_theme.dart';

/// HomePal amblemi (gülen ev).
///
/// Çizim android/app/src/main/res/drawable/splash_logo.xml ile birebir aynıdır
/// (240 birimlik viewport, 288 boyutta Android açılış ikonuyla aynı ölçek);
/// açılışta yerel ekrandan Flutter'a kesintisiz geçiş buna dayanır.
/// Biri değişirse diğeri de güncellenmeli.
class HomePalMark extends StatelessWidget {
  final double size;

  /// 0: gülen gözler açık, 1: gözler kapalı (göz kırpma animasyonu için)
  final double blink;

  const HomePalMark({super.key, this.size = 288, this.blink = 0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _MarkPainter(blink));
  }
}

/// "HomePal" yazısı: "Home" mavi, "Pal" turuncu (logodaki gibi).
class HomePalWordmark extends StatelessWidget {
  final double fontSize;
  const HomePalWordmark({super.key, this.fontSize = 36});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: "Home", style: TextStyle(color: context.styles.primaryColor)),
          const TextSpan(text: "Pal", style: TextStyle(color: AppStyles.accentColor)),
        ],
      ),
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: -0.5),
    );
  }
}

/// Açılış ekranından giriş ekranına geçerken amblem, yazı ve alt yazı yerlerine
/// uçar (Hero). İki ekranda aynı etiket ve aynı boyut kullanılmalı.
class BrandHero extends StatelessWidget {
  static const mark = 'homepal-mark';
  static const wordmark = 'homepal-wordmark';
  static const tagline = 'homepal-tagline';

  final String tag;
  final Widget child;
  const BrandHero({super.key, required this.tag, required this.child});

  @override
  Widget build(BuildContext context) {
    // Uçuş sırasında metinler Material dışında çizilir; şeffaf Material,
    // hata ayıklama modundaki sarı alt çizgiyi engeller.
    return Hero(tag: tag, child: Material(type: MaterialType.transparency, child: child));
  }
}

/// Açılış animasyonunun bittiği kompozisyondaki amblem boyutu (288 x 0.7)
const double kBrandMarkSize = 201.6;

class _MarkPainter extends CustomPainter {
  final double blink;
  _MarkPainter(this.blink);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 240);

    // Baca
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(146, 64, 164, 100,
          topLeft: const Radius.circular(4), topRight: const Radius.circular(4)),
      Paint()..color = const Color(0xFF3B82F6),
    );

    // Gövde (üst kenarı çatı çizgisinin altında kalır)
    final body = Path()
      ..moveTo(76, 97.2)
      ..lineTo(120, 62)
      ..lineTo(164, 97.2)
      ..lineTo(164, 160)
      ..arcToPoint(const Offset(150, 174), radius: const Radius.circular(14))
      ..lineTo(90, 174)
      ..arcToPoint(const Offset(76, 160), radius: const Radius.circular(14))
      ..close();
    canvas.drawPath(body, Paint()..color = AppStyles.accentColor);

    // Çatı
    canvas.drawPath(
      Path()
        ..moveTo(60, 110)
        ..lineTo(120, 62)
        ..lineTo(180, 110),
      Paint()
        ..color = AppStyles.brandBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Kapı
    final door = Path()
      ..moveTo(109, 174)
      ..lineTo(109, 160)
      ..arcToPoint(const Offset(131, 160), radius: const Radius.circular(11))
      ..lineTo(131, 174)
      ..close();
    canvas.drawPath(door, Paint()..color = AppStyles.brandBlue);

    // Yanaklar
    final cheek = Paint()..color = const Color(0xFFE8590C).withValues(alpha: 0.35);
    canvas.drawCircle(const Offset(94, 133), 6, cheek);
    canvas.drawCircle(const Offset(146, 133), 6, cheek);

    // Gözler (kırpınca düz çizgiye iner) ve gülüş
    final eyeTop = 113 + 9 * blink.clamp(0.0, 1.0);
    canvas.drawPath(
      Path()
        ..moveTo(96, 122)
        ..quadraticBezierTo(104, eyeTop, 112, 122)
        ..moveTo(128, 122)
        ..quadraticBezierTo(136, eyeTop, 144, 122)
        ..moveTo(106, 135)
        ..quadraticBezierTo(120, 147, 134, 135),
      Paint()
        ..color = AppStyles.brandNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.blink != blink;
}
