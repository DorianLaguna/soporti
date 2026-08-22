import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Tarjeta de indicador clave (KPI) para el panel del supervisor.
/// Muestra un icono, título descriptivo y valor formateado.
class KpiCard extends StatelessWidget {
  /// Título del KPI (e.g. "Tickets abiertos").
  final String title;

  /// Valor formateado como texto (e.g. "12", "4.5h", "85%").
  final String value;

  /// Icono representativo del KPI.
  final IconData icon;

  /// Color de acento para el icono y borde izquierdo.
  final Color accentColor;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor = AppColors.uvmGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Factory helpers para formateo de valores ────────────────────────

  /// Formatea el valor de tickets abiertos: entero o "0" si es cero.
  static String formatOpenTickets(int count) => count.toString();

  /// Formatea el promedio de resolución: "X.Xh" o "—" si es 0.
  static String formatAvgResolution(double hours) {
    if (hours == 0) return '—';
    return '${hours.toStringAsFixed(1)}h';
  }

  /// Formatea el % de cumplimiento SLA: "XX%" o "—" si no hay datos (0 sin tickets resueltos).
  static String formatSlaCompliance(int percent, {bool hasData = true}) {
    if (!hasData) return '—';
    return '$percent%';
  }

  /// Formatea la satisfacción promedio: "X.X" o "—" si es 0.
  static String formatSatisfaction(double avg) {
    if (avg == 0) return '—';
    return avg.toStringAsFixed(1);
  }
}
