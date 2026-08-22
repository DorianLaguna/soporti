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
/// Retorna `null` si no hay usuario logueado.
final currentUserProvider = FutureProvider<Profile?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;
  final data =
      await client.from('profiles').select().eq('id', user.id).single();
  return Profile.fromJson(data);
});
