import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgo/screens/open_match_alerts_screen.dart';

void main() {
  testWidgets('invalid match link shows a controlled error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OpenMatchDetailByIdScreen(
          openMatchAlertId: null,
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Enlace de partido'), findsOneWidget);
    expect(
      find.textContaining('Verifica que el enlace sea correcto'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
