import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/core/app_theme.dart';
import 'package:flutter_app/core/widgets/homepal_mark.dart';
import 'package:flutter_app/features/auth/login_screen.dart';

void main() {
  testWidgets('HomePal amblemi çizilir (göz kırpma dahil)', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Center(child: HomePalMark(blink: 0.5))));
    expect(find.byType(HomePalMark), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Giriş ekranı e-posta ve şifre alanlarını gösterir', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const LoginScreen()));
    expect(find.widgetWithText(TextField, 'Ev ortak e-postası'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Şifre'), findsOneWidget);
  });
}
