import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../models/dashboard_kpis.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/category_chart.dart';
import '../widgets/kpi_card.dart';
import '../widgets/workload_chart.dart';

/// Pantalla principal del supervisor: Panel de Indicadores.
/// Muestra KPIs en cuadrícula 2×2, gráfico de distribución por categoría
/// y gráfico de carga por técnico.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final kpisAsync = ref.watch(dashboardKPIsProvider);
    final categoryAsync = ref.watch(categoryDistributionProvider);
    final workloadAsync = ref.watch(techWorkloadProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardKPIsProvider);
            ref.invalidate(categoryDistributionProvider);
            ref.invalidate(techWorkloadProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Encabezado con periodo ────────────────────────────
                _buildHeader(context),
                const SizedBox(height: 20),

                // ─── Cuadrícula 2×2 de KPIs ───────────────────────────
                kpisAsync.when(
                  data: (kpis) => _buildKpiGrid(context, kpis),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => _buildErrorWidget(
                    context,
                    onRetry: () => ref.invalidate(dashboardKPIsProvider),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Gráfico de distribución por categoría ────────────
                categoryAsync.when(
                  data: (data) => CategoryChart(data: data),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => _buildErrorWidget(
                    context,
                    onRetry: () =>
                        ref.invalidate(categoryDistributionProvider),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Gráfico de carga por técnico ─────────────────────
                workloadAsync.when(
                  data: (data) => WorkloadChart(data: data),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => _buildErrorWidget(
                    context,
                    onRetry: () => ref.invalidate(techWorkloadProvider),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: AppStrings.navDashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            label: AppStrings.navTickets,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            label: AppStrings.navTeam,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: AppStrings.navProfile,
          ),
        ],
      ),
    );
  }

  /// Encabezado que muestra el periodo actual: "[Mes] [Año] · a la fecha".
  Widget _buildHeader(BuildContext context) {
    final period = ref.watch(dashboardPeriodProvider);
    final monthName = _getSpanishMonth(period.from.month);
    final year = period.from.year.toString();
    final periodText = '$monthName $year${AppStrings.periodSuffix}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.dashboard,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          periodText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  /// Cuadrícula 2×2 con las 4 tarjetas KPI.
  Widget _buildKpiGrid(BuildContext context, DashboardKPIs kpis) {
    // Determinar si hay datos de tickets resueltos para SLA y satisfacción.
    final hasResolvedData = kpis.slaCompliancePercent > 0 ||
        kpis.avgResolutionHours > 0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      // 1.3 no dejaba espacio suficiente cuando el título ocupa 2 líneas
      // (p. ej. "Tiempo prom. resolución"), causando overflow vertical.
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        KpiCard(
          title: AppStrings.kpiOpenTickets,
          value: KpiCard.formatOpenTickets(kpis.openTickets),
          icon: Icons.confirmation_number_outlined,
          accentColor: AppColors.statusAbierto,
        ),
        KpiCard(
          title: AppStrings.kpiAvgResolution,
          value: KpiCard.formatAvgResolution(kpis.avgResolutionHours),
          icon: Icons.schedule,
          accentColor: AppColors.secondary,
        ),
        KpiCard(
          title: AppStrings.kpiSlaCompliance,
          value: KpiCard.formatSlaCompliance(
            kpis.slaCompliancePercent,
            hasData: hasResolvedData,
          ),
          icon: Icons.verified_outlined,
          accentColor: AppColors.statusResuelto,
        ),
        KpiCard(
          title: AppStrings.kpiSatisfaction,
          value: KpiCard.formatSatisfaction(kpis.avgSatisfaction),
          icon: Icons.star_outline,
          accentColor: AppColors.secondary,
        ),
      ],
    );
  }

  /// Widget genérico de error con botón de reintentar.
  Widget _buildErrorWidget(BuildContext context, {required VoidCallback onRetry}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 32, color: AppColors.error),
            const SizedBox(height: 8),
            Text(AppStrings.error,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  /// Navega a la pantalla correspondiente según la pestaña seleccionada.
  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 0:
        // Ya estamos en Indicadores.
        break;
      case 1:
        context.push('/supervisor-tickets');
        break;
      case 2:
        // Equipo — por implementar en otra tarea.
        break;
      case 3:
        context.push('/profile');
        break;
    }
  }

  /// Retorna el nombre del mes en español.
  String _getSpanishMonth(int month) {
    // Usar intl con locale es para formatear el nombre del mes.
    final date = DateTime(2024, month);
    final formatter = DateFormat.MMMM('es');
    final name = formatter.format(date);
    // Capitalizar primera letra.
    return name[0].toUpperCase() + name.substring(1);
  }
}
