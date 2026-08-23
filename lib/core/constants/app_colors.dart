import 'package:flutter/material.dart';

/// Colores centralizados de la aplicación SoporTI.
/// Basado en la paleta oficial: azules como base, colores de prioridad
/// ligados al SLA comprometido, y estados de ticket armonizados con la base.
class AppColors {
  AppColors._();

  // ─── Colores base ─────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B4965); // Azul profundo
  static const Color primaryDark = Color(0xFF12303F); // Variante oscura
  static const Color primaryContainer = Color(0xFFCAE9FF); // Azul claro
  static const Color secondary = Color(0xFF5FA8D3); // Azul medio (acentos)

  // ─── Colores de prioridad (con SLA comprometido) ─────────────────────
  static const Color priorityBaja = Color(0xFF4CAF50); // Verde — 72 h
  static const Color priorityMedia = Color(0xFFFFC107); // Ámbar — 24 h
  static const Color priorityAlta = Color(0xFFFF7043); // Naranja — 8 h
  static const Color priorityCritica = Color(0xFFD32F2F); // Rojo — 2 h

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

  // ─── Colores de estatus (armonizados con la base azul) ───────────────
  static const Color statusAbierto = Color(0xFF5FA8D3); // Azul medio
  static const Color statusAsignado = Color(0xFF1B4965); // Azul profundo
  static const Color statusEnProceso = Color(0xFFFF7043); // Naranja
  static const Color statusEnEspera = Color(0xFF6B7280); // Gris
  static const Color statusResuelto = Color(0xFF4CAF50); // Verde
  static const Color statusCerrado = Color(0xFF4B5563); // Gris oscuro

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

  /// Color de texto (blanco o casi negro) con mejor contraste sobre [background].
  static Color onColor(Color background) {
    return background.computeLuminance() > 0.5 ? textPrimary : Colors.white;
  }

  // ─── Colores de estado offline ───────────────────────────────────────
  static const Color offlineBanner = Color(0xFFFFD700); // Dorado/amarillo
  static const Color offlineBackground = Color(0xFFFFF8E1); // Fondo dorado claro
  static const Color offlineBorder = Color(0xFFFFD700); // Borde punteado amarillo
  static const Color offlineText = Color(0xFF5D4037); // Texto oscuro sobre dorado

  // ─── Colores de línea de tiempo ──────────────────────────────────────
  static const Color timelineRegular = Color(0xFF5FA8D3); // Azul medio
  static const Color timelineResolution = Color(0xFF4CAF50); // Verde

  // ─── Colores generales de UI ─────────────────────────────────────────
  static const Color surface = Color(0xFFF7F9FB); // Casi blanco (fondo general)
  static const Color surfaceCard = Colors.white; // Superficie de tarjetas
  static const Color error = Color(0xFFD32F2F);
  static const Color textPrimary = Color(0xFF1C1C1E); // Casi negro
  static const Color textSecondary = Color(0xFF6B7280); // Gris (metadatos)
  static const Color divider = Color(0xFFE2E8F0);

  // ─── SLA warning ────────────────────────────────────────────────────
  static const Color slaWarning = Color(0xFFD32F2F); // Rojo para < 2h restantes
}
