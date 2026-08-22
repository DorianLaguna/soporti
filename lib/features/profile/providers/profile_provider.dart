import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider que expone el perfil del usuario autenticado.
/// Reutiliza [currentUserProvider] de la capa de autenticación.
final profileProvider = FutureProvider<Profile?>((ref) {
  return ref.watch(currentUserProvider.future);
});
