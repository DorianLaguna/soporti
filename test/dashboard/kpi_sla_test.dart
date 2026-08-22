// Feature: soporti-app, Property 13: KPI — SLA compliance percentage
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// Datos de un ticket resuelto para cálculo de SLA compliance.
class ResolvedTicketData {
  final String priority;
  final Duration resolutionTime;

  const ResolvedTicketData({
    required this.priority,
    required this.resolutionTime,
  });

  @override
  String toString() =>
      'ResolvedTicketData(priority: $priority, resolutionTime: ${resolutionTime.inMinutes}min)';
}

/// Mapeo de prioridad a duración SLA máxima.
const _slaLimits = {
  'Crítica': Duration(hours: 4),
  'Alta': Duration(hours: 8),
  'Media': Duration(hours: 24),
  'Baja': Duration(hours: 48),
};

/// Prioridades válidas del sistema.
const _priorities = ['Crítica', 'Alta', 'Media', 'Baja'];

/// Calcula el porcentaje de cumplimiento SLA de un conjunto de tickets resueltos.
///
/// Para cada ticket, verifica si el tiempo de resolución es <= al límite SLA
/// según su prioridad. Retorna (cumplieron / total * 100).round().
///
/// Si la lista está vacía, retorna 0.
int calculateSlaCompliance(List<ResolvedTicketData> tickets) {
  if (tickets.isEmpty) return 0;

  int withinSla = 0;
  for (final ticket in tickets) {
    final slaLimit = _slaLimits[ticket.priority] ?? const Duration(hours: 24);
    if (ticket.resolutionTime <= slaLimit) {
      withinSla++;
    }
  }

  return ((withinSla / tickets.length) * 100).round();
}

void main() {
  // Feature: soporti-app, Property 13: KPI — SLA compliance percentage
  // **Validates: Requirements 7.1, 7.5**
  group('Property 13: KPI — SLA compliance percentage', () {
    // Usamos listas de pares (priorityIndex, minutes) para generar tickets.
    // priorityIndex: 0-3 (Crítica, Alta, Media, Baja)
    // minutes: 0-6000 (0 a 100 horas en minutos)
    Glados(any.list(any.combine2(any.intInRange(0, 4), any.intInRange(0, 6000),
            (a, b) => (priorityIdx: a, minutes: b))),
        ExploreConfig(numRuns: 100)).test(
      'SLA compliance % = (within SLA / total) × 100 rounded',
      (ticketData) {
        if (ticketData.isEmpty) return; // Skip vacíos

        final tickets = ticketData
            .map((d) => ResolvedTicketData(
                  priority: _priorities[d.priorityIdx],
                  resolutionTime: Duration(minutes: d.minutes),
                ))
            .toList();

        final result = calculateSlaCompliance(tickets);

        // Cálculo manual de verificación
        int withinSla = 0;
        for (final ticket in tickets) {
          final slaLimit =
              _slaLimits[ticket.priority] ?? const Duration(hours: 24);
          if (ticket.resolutionTime <= slaLimit) {
            withinSla++;
          }
        }
        final expected = ((withinSla / tickets.length) * 100).round();

        expect(result, equals(expected));
      },
    );

    Glados(any.list(any.combine2(any.intInRange(0, 4), any.intInRange(0, 6000),
            (a, b) => (priorityIdx: a, minutes: b))),
        ExploreConfig(numRuns: 100)).test(
      'resultado siempre está entre 0 y 100 inclusive',
      (ticketData) {
        if (ticketData.isEmpty) return;

        final tickets = ticketData
            .map((d) => ResolvedTicketData(
                  priority: _priorities[d.priorityIdx],
                  resolutionTime: Duration(minutes: d.minutes),
                ))
            .toList();

        final result = calculateSlaCompliance(tickets);

        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThanOrEqualTo(100));
      },
    );

    Glados(any.intInRange(1, 20), ExploreConfig(numRuns: 100)).test(
      'todos dentro de SLA → resultado es 100%',
      (count) {
        // Crear tickets que están definitivamente dentro del SLA (0 minutos de resolución)
        final tickets = List.generate(
          count,
          (i) => ResolvedTicketData(
            priority: _priorities[i % _priorities.length],
            resolutionTime: Duration.zero,
          ),
        );

        final result = calculateSlaCompliance(tickets);
        expect(result, equals(100));
      },
    );

    Glados(any.intInRange(1, 20), ExploreConfig(numRuns: 100)).test(
      'ninguno dentro de SLA → resultado es 0%',
      (count) {
        // Crear tickets que exceden el SLA máximo (Baja=48h, usar 49h)
        final tickets = List.generate(
          count,
          (i) => ResolvedTicketData(
            priority: _priorities[i % _priorities.length],
            resolutionTime: const Duration(hours: 49),
          ),
        );

        final result = calculateSlaCompliance(tickets);
        expect(result, equals(0));
      },
    );

    test('lista vacía retorna 0', () {
      final result = calculateSlaCompliance([]);
      expect(result, equals(0));
    });

    test('un ticket dentro de SLA, uno fuera → 50%', () {
      final tickets = [
        // Crítica, resuelto en 2h → dentro de SLA (4h)
        const ResolvedTicketData(
          priority: 'Crítica',
          resolutionTime: Duration(hours: 2),
        ),
        // Crítica, resuelto en 5h → fuera de SLA (4h)
        const ResolvedTicketData(
          priority: 'Crítica',
          resolutionTime: Duration(hours: 5),
        ),
      ];

      final result = calculateSlaCompliance(tickets);
      expect(result, equals(50));
    });

    test('ticket resuelto exactamente en el límite SLA es dentro de SLA', () {
      // Baja: 48h exactas debe ser cumplido
      final tickets = [
        const ResolvedTicketData(
          priority: 'Baja',
          resolutionTime: Duration(hours: 48),
        ),
      ];

      final result = calculateSlaCompliance(tickets);
      expect(result, equals(100));
    });

    test('ticket resuelto 1 minuto después del SLA es fuera de SLA', () {
      // Alta: 8h + 1min excede
      final tickets = [
        const ResolvedTicketData(
          priority: 'Alta',
          resolutionTime: Duration(hours: 8, minutes: 1),
        ),
      ];

      final result = calculateSlaCompliance(tickets);
      expect(result, equals(0));
    });

    Glados2(any.intInRange(0, 20), any.intInRange(0, 20),
            ExploreConfig(numRuns: 100))
        .test(
      'compliance con mezcla de dentro/fuera SLA calcula correctamente',
      (withinCount, outsideCount) {
        if (withinCount + outsideCount == 0) return; // Skip lista vacía

        // Tickets definitivamente dentro de SLA (resolución instantánea)
        final withinTickets = List.generate(
          withinCount,
          (i) => ResolvedTicketData(
            priority: _priorities[i % _priorities.length],
            resolutionTime: Duration.zero,
          ),
        );

        // Tickets definitivamente fuera de SLA (49h, más que el máximo de 48h)
        final outsideTickets = List.generate(
          outsideCount,
          (i) => ResolvedTicketData(
            priority: _priorities[i % _priorities.length],
            resolutionTime: const Duration(hours: 49),
          ),
        );

        final allTickets = [...withinTickets, ...outsideTickets];
        final result = calculateSlaCompliance(allTickets);
        final total = withinCount + outsideCount;
        final expected = ((withinCount / total) * 100).round();

        expect(result, equals(expected));
      },
    );
  });
}
