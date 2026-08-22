import 'package:flutter/material.dart';

/// Colores centralizados de la aplicación SoporTI.
/// Incluye colores institucionales UVM, prioridades, estatus y estado offline.
class AppColors {
  AppColors._();

  // ─── Colores institucionales UVM ─────────────────────────────────────
  static const Color uvmGreen = Color(0xFF006633);
  static const Color uvmGreenDark = Color(0xFF004D26);
  static const Color uvmGreenLight = Color(0xFF339966);
  static const Color uvmGold = Color(0xFFB8860B);

  // ─── Colores de prioridad ────────────────────────────────────────────
  static const Color priorityCritica = Color(0xFFE53935); // Rojo
  static const Color priorityAlta = Color(0xFFFB8C00); // Naranja
  static const Color priorityMedia = Color(0xFFFDD835); // Amarillo
  static const Color priorityBaja = Color(0xFF43A047); // Verde

  /// Obtiene el color correspondiente a una prioridad.
  static Color priorityColor(String priority) {
    return switch (priority) {
      'Crítica' => priorityCritica,
      'Alta' => priorityAlta,
      'Media' => priorityMedia,
      'Baja' => priorityBaja,
      _ => Colors.grey,
    };
  }

  // ─── Colores de estatus ──────────────────────────────────────────────
  static const Color statusAbierto = Color(0xFF1E88E5); // Azul
  static const Color statusAsignado = Color(0xFF5E35B1); // Púrpura
  static const Color statusEnProceso = Color(0xFFFB8C00); // Naranja
  static const Color statusEnEspera = Color(0xFF8D6E63); // Café
  static const Color statusResuelto = Color(0xFF43A047); // Verde
  static const Color statusCerrado = Color(0xFF757575); // Gris

  /// Obtiene el color correspondiente a un estatus.
  static Color statusColor(String status) {
    return switch (status) {
      'Abierto' => statusAbierto,
      'Asignado' => statusAsignado,
      'En proceso' => statusEnProceso,
      'En espera' => statusEnEspera,
      'Resuelto' => statusResuelto,
      'Cerrado' => statusCerrado,
      _ => Colors.grey,
    };
  }

  // ─── Colores de estado offline ───────────────────────────────────────
  static const Color offlineBanner = Color(0xFFFFD700); // Dorado/amarillo
  static const Color offlineBackground = Color(0xFFFFF8E1); // Fondo dorado claro
  static const Color offlineBorder = Color(0xFFFFD700); // Borde punteado amarillo
  static const Color offlineText = Color(0xFF5D4037); // Texto oscuro sobre dorado

  // ─── Colores de línea de tiempo ──────────────────────────────────────
  static const Color timelineRegular = Color(0xFF1E88E5); // Azul
  static const Color timelineResolution = Color(0xFF43A047); // Verde

  // ─── Colores generales de UI ─────────────────────────────────────────
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);

  // ─── SLA warning ────────────────────────────────────────────────────
  static const Color slaWarning = Color(0xFFE53935); // Rojo para < 2h restantes
}
