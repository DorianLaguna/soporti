import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soporti/app.dart';

void main() {
  testWidgets('SoporTIApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SoporTIApp(),
      ),
    );

    // Verify the placeholder screen renders
    expect(find.text('SoporTI — Cargando...'), findsOneWidget);
  });
}
