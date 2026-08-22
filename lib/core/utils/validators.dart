import 'package:soporti/core/constants/app_strings.dart';

/// Funciones puras de validación para formularios de la app.
/// Usadas en login y creación de tickets.

/// Valida que un campo de correo electrónico no esté vacío y tenga formato válido.
/// Retorna mensaje de error o `null` si es válido.
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppStrings.fieldRequired;
  }
  final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
  if (!emailRegex.hasMatch(value.trim())) {
    return AppStrings.invalidEmailFormat;
  }
  return null;
}

/// Valida que un campo obligatorio no esté vacío ni sea solo whitespace.
/// Retorna mensaje de error o `null` si es válido.
String? validateRequired(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppStrings.fieldRequired;
  }
  return null;
}

/// Valida el título de un ticket: requerido, entre 5 y 100 caracteres.
/// Retorna mensaje de error o `null` si es válido.
String? validateTitle(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppStrings.fieldRequired;
  }
  final trimmed = value.trim();
  if (trimmed.length < 5) {
    return AppStrings.titleMinLength;
  }
  if (trimmed.length > 100) {
    return AppStrings.titleMaxLength;
  }
  return null;
}

/// Valida la descripción de un ticket: requerida, entre 10 y 1000 caracteres.
/// Retorna mensaje de error o `null` si es válido.
String? validateDescription(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppStrings.fieldRequired;
  }
  final trimmed = value.trim();
  if (trimmed.length < 10) {
    return AppStrings.descriptionMinLength;
  }
  if (trimmed.length > 1000) {
    return AppStrings.descriptionMaxLength;
  }
  return null;
}
