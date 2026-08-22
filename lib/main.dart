import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(
    _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty,
    'Faltan SUPABASE_URL/SUPABASE_ANON_KEY. Corre con '
    '--dart-define-from-file=env/dev.json (ver supabase/README.md).',
  );

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseAnonKey,
  );

  // Inicializar datos de formato de fecha para locale español.
  await initializeDateFormatting('es');

  runApp(
    const ProviderScope(
      child: SoporTIApp(),
    ),
  );
}
