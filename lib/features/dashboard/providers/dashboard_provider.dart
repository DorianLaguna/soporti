import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_kpis.dart';
import '../repositories/dashboard_repository.dart';

/// Provider que expone el rango del periodo actual (mes en curso).
/// from = primer día del mes actual, to = ahora.
final dashboardPeriodProvider = Provider<({DateTime from, DateTime to})>((ref) {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, 1);
  return (from: from, to: now);
});

/// FutureProvider que obtiene los KPIs del periodo actual.
/// Retorna DashboardKPIs con: tickets abiertos, avg resolución, % SLA, satisfacción.
final dashboardKPIsProvider = FutureProvider<DashboardKPIs>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final period = ref.watch(dashboardPeriodProvider);
  return repository.getKPIs(period.from, period.to);
});

/// FutureProvider que obtiene la distribución de tickets por categoría del periodo.
/// Retorna `Map<String, int>` donde key = categoría, value = cantidad.
final categoryDistributionProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final period = ref.watch(dashboardPeriodProvider);
  return repository.getCategoryDistribution(period.from, period.to);
});

/// FutureProvider que obtiene la carga de trabajo por técnico.
/// Retorna `Map<String, int>` donde key = nombre abreviado del técnico, value = tickets activos.
final techWorkloadProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getTechWorkload();
});
