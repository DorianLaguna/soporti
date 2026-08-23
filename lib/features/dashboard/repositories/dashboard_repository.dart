import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../models/ticket.dart';
import '../models/dashboard_kpis.dart';

/// Repositorio que abstrae las queries del panel de indicadores del supervisor.
class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository(this._client);

  /// Estatus activos para conteo de tickets abiertos.
  static const _activeStatuses = [
    'Abierto',
    'Asignado',
    'En proceso',
    'En espera',
  ];

  /// Estatus resueltos/cerrados para métricas de rendimiento.
  static const _resolvedStatuses = ['Resuelto', 'Cerrado'];

  /// Mapeo de prioridad a horas máximas del SLA.
  static const _slaHoursMap = {
    'Crítica': 4,
    'Alta': 8,
    'Media': 24,
    'Baja': 48,
  };

  /// Obtiene los KPIs del periodo [from] a [to].
  ///
  /// - Tickets abiertos: status activo AND created_at >= from
  /// - Tiempo promedio de resolución: promedio de (resolved_at - created_at) en horas
  /// - % SLA: tickets resueltos dentro del límite SLA / total resueltos × 100
  /// - Satisfacción: promedio de ratings no nulos
  ///
  /// Lanza [NotFoundException] si hay error en queries de Supabase.
  /// Lanza [NetworkException] si hay problema de conexión.
  Future<DashboardKPIs> getKPIs(DateTime from, DateTime to) async {
    try {
      final fromStr = from.toUtc().toIso8601String();
      final toStr = to.toUtc().toIso8601String();

      // 1. Tickets abiertos en el periodo
      final openResponse = await _client
          .from('tickets')
          .select('id')
          .inFilter('status', _activeStatuses)
          .gte('created_at', fromStr)
          .lte('created_at', toStr);
      final openTickets = (openResponse as List<dynamic>).length;

      // 2. Tickets resueltos/cerrados en el periodo (para avg resolución y SLA)
      final resolvedResponse = await _client
          .from('tickets')
          .select('created_at, resolved_at, priority')
          .inFilter('status', _resolvedStatuses)
          .not('resolved_at', 'is', null)
          .gte('resolved_at', fromStr)
          .lte('resolved_at', toStr);
      final resolvedTickets = resolvedResponse as List<dynamic>;

      // Calcular tiempo promedio de resolución en horas
      double avgResolutionHours = 0;
      int slaCompliancePercent = 0;

      if (resolvedTickets.isNotEmpty) {
        double totalHours = 0;
        int withinSla = 0;

        for (final ticket in resolvedTickets) {
          final createdAt =
              DateTime.parse(ticket['created_at'] as String);
          final resolvedAt =
              DateTime.parse(ticket['resolved_at'] as String);
          final priority = ticket['priority'] as String;

          final resolutionHours =
              resolvedAt.difference(createdAt).inMinutes / 60.0;
          totalHours += resolutionHours;

          // Verificar cumplimiento SLA
          final slaLimitHours = _slaHoursMap[priority] ?? 24;
          if (resolutionHours <= slaLimitHours) {
            withinSla++;
          }
        }

        avgResolutionHours = totalHours / resolvedTickets.length;
        slaCompliancePercent =
            ((withinSla / resolvedTickets.length) * 100).round();
      }

      // 3. Satisfacción promedio (tickets con rating en el periodo)
      final ratingResponse = await _client
          .from('tickets')
          .select('rating')
          .not('rating', 'is', null)
          .gte('updated_at', fromStr)
          .lte('updated_at', toStr);
      final ratedTickets = ratingResponse as List<dynamic>;

      double avgSatisfaction = 0;
      if (ratedTickets.isNotEmpty) {
        double totalRating = 0;
        for (final ticket in ratedTickets) {
          totalRating += (ticket['rating'] as int).toDouble();
        }
        avgSatisfaction = totalRating / ratedTickets.length;
      }

      return DashboardKPIs(
        openTickets: openTickets,
        avgResolutionHours: avgResolutionHours,
        slaCompliancePercent: slaCompliancePercent,
        avgSatisfaction: avgSatisfaction,
      );
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al obtener KPIs: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }

  /// Obtiene la distribución de tickets por categoría en el periodo [from] a [to].
  /// Retorna un Map donde key = categoría, value = cantidad de tickets.
  ///
  /// Lanza [NotFoundException] si hay error en queries de Supabase.
  /// Lanza [NetworkException] si hay problema de conexión.
  Future<Map<String, int>> getCategoryDistribution(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final fromStr = from.toUtc().toIso8601String();
      final toStr = to.toUtc().toIso8601String();

      final response = await _client
          .from('tickets')
          .select('category')
          .gte('created_at', fromStr)
          .lte('created_at', toStr);

      final tickets = response as List<dynamic>;
      final distribution = <String, int>{};

      for (final ticket in tickets) {
        final category = ticket['category'] as String;
        distribution[category] = (distribution[category] ?? 0) + 1;
      }

      return distribution;
    } on PostgrestException catch (e) {
      throw NotFoundException(
          'Error al obtener distribución por categoría: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }

  /// Obtiene la carga de trabajo por técnico.
  /// Cuenta tickets activos (estatus Abierto, Asignado, En proceso, En espera)
  /// asignados a cada técnico.
  /// Retorna un Map donde key = nombre abreviado del técnico, value = cantidad.
  ///
  /// Lanza [NotFoundException] si hay error en queries de Supabase.
  /// Lanza [NetworkException] si hay problema de conexión.
  Future<Map<String, int>> getTechWorkload() async {
    try {
      // Obtener tickets activos con técnico asignado
      final response = await _client
          .from('tickets')
          .select('assigned_to')
          .inFilter('status', _activeStatuses)
          .not('assigned_to', 'is', null);

      final tickets = response as List<dynamic>;

      // Contar tickets por técnico (por ID)
      final countById = <String, int>{};
      for (final ticket in tickets) {
        final techId = ticket['assigned_to'] as String;
        countById[techId] = (countById[techId] ?? 0) + 1;
      }

      if (countById.isEmpty) return {};

      // Obtener nombres de técnicos
      final techIds = countById.keys.toList();
      final profilesResponse = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', techIds);

      final profiles = profilesResponse as List<dynamic>;

      // Mapear ID → nombre abreviado y armar resultado
      final workload = <String, int>{};
      for (final profile in profiles) {
        final id = profile['id'] as String;
        final fullName = profile['full_name'] as String;
        final abbreviated = _abbreviateName(fullName);
        workload[abbreviated] = countById[id] ?? 0;
      }

      return workload;
    } on PostgrestException catch (e) {
      throw NotFoundException(
          'Error al obtener carga por técnico: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }

  /// Abrevia un nombre completo a "Nombre A." (primer nombre + inicial del apellido).
  String _abbreviateName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return fullName;
    return '${parts.first} ${parts.last[0]}.';
  }

  /// Obtiene todos los tickets de la organización, sin filtrar por
  /// solicitante ni técnico asignado. Solo accesible para el rol supervisor
  /// (la política RLS "tickets_select" restringe el resto de roles).
  Future<List<Ticket>> getAllTickets() async {
    try {
      final response = await _client
          .from('tickets')
          .select()
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al obtener tickets: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }
}

/// Provider que expone el repositorio del dashboard.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DashboardRepository(client);
});
