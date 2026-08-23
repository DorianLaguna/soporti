import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../models/profile.dart';

/// Provider que emite cambios en el estado de autenticación (login/logout).
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// Provider que obtiene el perfil del usuario autenticado desde la tabla `profiles`.
/// Retorna `null` si no hay usuario logueado o si la sesión no tiene un perfil
/// asociado (p. ej. una sesión local obsoleta cuya fila en `profiles` ya no existe).
final currentUserProvider = FutureProvider<Profile?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  // `client.auth.currentUser` es un getter mutable, no reactivo: sin este
  // watch, el provider se calcula una sola vez (con la sesión que hubiera
  // al arrancar la app) y queda cacheado para siempre, ignorando logins o
  // logouts posteriores. Escuchar authStateProvider fuerza a recalcular
  // cada vez que cambia la sesión.
  ref.watch(authStateProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;
  try {
    final data =
        await client.from('profiles').select().eq('id', user.id).single();
    return Profile.fromJson(data);
  } on PostgrestException catch (e) {
    debugPrint(
      'currentUserProvider: error al buscar profiles.id=${user.id}: '
      'code=${e.code} message=${e.message} details=${e.details}',
    );
    if (e.code == 'PGRST116') return null;
    rethrow;
  } catch (e) {
    debugPrint('currentUserProvider: error inesperado: $e');
    rethrow;
  }
});
