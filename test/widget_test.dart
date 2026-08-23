import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soporti/app.dart';

void main() {
  setUpAll(() async {
    // SoporTIApp depende de Supabase.instance (vía supabaseClientProvider)
    // desde el primer build. En la app real esto lo inicializa main.dart;
    // en el test se usa un proyecto ficticio: no se hace ninguna llamada de
    // red en initialize(), solo se configuran los clientes locales.
    // Supabase persiste la sesión en shared_preferences, que necesita un
    // valor inicial simulado para funcionar fuera de un dispositivo real.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets('SoporTIApp renders the login screen when there is no session',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SoporTIApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SoporTI'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
