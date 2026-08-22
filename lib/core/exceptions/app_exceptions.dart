/// Excepciones de dominio de la aplicación.
/// Usa clases selladas para tipado exhaustivo en el manejo de errores.
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Error de autenticación (login fallido, sesión inválida, etc.).
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Error de validación de formulario con errores por campo.
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;
  const ValidationException(super.message, this.fieldErrors);
}

/// Error de conectividad de red.
class NetworkException extends AppException {
  const NetworkException() : super('Sin conexión a internet');
}

/// Error al subir/descargar archivos de Supabase Storage.
class StorageException extends AppException {
  const StorageException(super.message);
}

/// Recurso no encontrado (ticket eliminado, RLS, etc.).
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}
