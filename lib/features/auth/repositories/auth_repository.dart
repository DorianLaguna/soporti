import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/providers/supabase_provider.dart';

/// Repositorio que abstrae las operaciones de autenticación contra Supabase.
class AuthRepository {
  final supabase.SupabaseClient _client;

  AuthRepository(this._client);

  /// Inicia sesión con correo y contraseña.
  /// Lanza [AuthException] si las credenciales son inválidas o hay un error de red.
  Future<supabase.AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on supabase.AuthException catch (_) {
      // No revelar si el correo existe o no (Req 1.2).
      throw const AuthException('Correo o contraseña incorrectos');
    } catch (e) {
      throw const AuthException(
        'Error al iniciar sesión. Verifica tu conexión e intenta de nuevo.',
      );
    }
  }

  /// Cierra la sesión activa del usuario.
  /// Lanza [AuthException] si ocurre un error al cerrar sesión.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (_) {
      throw const AuthException('Error al cerrar sesión.');
    }
  }

  /// Envía un correo de restablecimiento de contraseña.
  /// Lanza [AuthException] si ocurre un error durante el envío.
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (_) {
      throw const AuthException(
        'Error al enviar correo de restablecimiento. Intenta de nuevo.',
      );
    }
  }
}

/// Provider que expone el repositorio de autenticación.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});
