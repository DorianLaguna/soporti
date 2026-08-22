/// Modelo que representa los KPIs del panel de indicadores del supervisor.
/// Contiene métricas clave del periodo seleccionado.
class DashboardKPIs {
  /// Cantidad de tickets con estatus activo en el periodo.
  final int openTickets;

  /// Promedio de horas entre creación y resolución.
  final double avgResolutionHours;

  /// Porcentaje de tickets resueltos dentro del SLA (0–100).
  final int slaCompliancePercent;

  /// Promedio de ratings de tickets calificados (1.0–5.0).
  final double avgSatisfaction;

  const DashboardKPIs({
    required this.openTickets,
    required this.avgResolutionHours,
    required this.slaCompliancePercent,
    required this.avgSatisfaction,
  });

  /// Valor vacío cuando no hay datos en el periodo.
  static const empty = DashboardKPIs(
    openTickets: 0,
    avgResolutionHours: 0,
    slaCompliancePercent: 0,
    avgSatisfaction: 0,
  );
}
