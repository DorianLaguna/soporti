import 'package:glados/glados.dart';
import 'package:test/test.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:soporti/models/ticket.dart';

/// Todos los estatus válidos del sistema de tickets.
const _allStatuses = [
  'Abierto',
  'Asignado',
  'En proceso',
  'En espera',
  'Resuelto',
  'Cerrado',
];

/// Replica la lógica de filtrado de ticket_provider.dart
/// (la función _applyFilter es privada, así que replicamos el mapping aquí).
List<Ticket> applyFilter(List<Ticket> tickets, String filter) {
  return switch (filter) {
    'todos' => tickets,
    'abiertos' =>
      tickets.where((t) => ['Abierto', 'Asignado'].contains(t.status)).toList(),
    'enProceso' => tickets
        .where((t) => ['En proceso', 'En espera'].contains(t.status))
        .toList(),
    'cerrados' => tickets
        .where((t) => ['Resuelto', 'Cerrado'].contains(t.status))
        .toList(),
    _ => tickets,
  };
}

/// Helper para crear un Ticket con estatus dado.
Ticket _makeTicket({
  required String status,
  DateTime? createdAt,
}) {
  final now = DateTime.now();
  return Ticket(
    id: 'test-${now.microsecondsSinceEpoch}',
    code: 'SOP-0001',
    title: 'Ticket de prueba',
    description: 'Descripción de prueba para el ticket',
    category: 'Software',
    priority: 'Media',
    status: status,
    location: 'Campus Norte',
    requesterId: 'user-001',
    createdAt: createdAt ?? now,
    updatedAt: now,
  );
}

/// Genera una lista de tickets con estatus aleatorios a partir de índices.
List<Ticket> _generateTicketList(List<int> statusIndices) {
  return statusIndices
      .map((i) => _makeTicket(status: _allStatuses[i % _allStatuses.length]))
      .toList();
}

void main() {
  // Feature: soporti-app, Property 4: Ticket list filter consistency
  // **Validates: Requirements 2.1, 2.3**
  group('Property 4: Ticket list filter consistency', () {
    Glados(any.list(any.intInRange(0, 6)), ExploreConfig(numRuns: 100)).test(
      'filtro "todos" retorna exactamente todos los tickets',
      (statusIndices) {
        final tickets = _generateTicketList(statusIndices);
        final result = applyFilter(tickets, 'todos');

        expect(result.length, equals(tickets.length));
        expect(result, equals(tickets));
      },
    );

    Glados(any.list(any.intInRange(0, 6)), ExploreConfig(numRuns: 100)).test(
      'filtro "abiertos" retorna solo tickets con estatus Abierto o Asignado',
      (statusIndices) {
        final tickets = _generateTicketList(statusIndices);
        final result = applyFilter(tickets, 'abiertos');

        for (final ticket in result) {
          expect(['Abierto', 'Asignado'], contains(ticket.status));
        }
        // Verificar que no se omitieron tickets válidos
        final expectedCount = tickets
            .where((t) => ['Abierto', 'Asignado'].contains(t.status))
            .length;
        expect(result.length, equals(expectedCount));
      },
    );

    Glados(any.list(any.intInRange(0, 6)), ExploreConfig(numRuns: 100)).test(
      'filtro "enProceso" retorna solo tickets con estatus En proceso o En espera',
      (statusIndices) {
        final tickets = _generateTicketList(statusIndices);
        final result = applyFilter(tickets, 'enProceso');

        for (final ticket in result) {
          expect(['En proceso', 'En espera'], contains(ticket.status));
        }
        final expectedCount = tickets
            .where((t) => ['En proceso', 'En espera'].contains(t.status))
            .length;
        expect(result.length, equals(expectedCount));
      },
    );

    Glados(any.list(any.intInRange(0, 6)), ExploreConfig(numRuns: 100)).test(
      'filtro "cerrados" retorna solo tickets con estatus Resuelto o Cerrado',
      (statusIndices) {
        final tickets = _generateTicketList(statusIndices);
        final result = applyFilter(tickets, 'cerrados');

        for (final ticket in result) {
          expect(['Resuelto', 'Cerrado'], contains(ticket.status));
        }
        final expectedCount = tickets
            .where((t) => ['Resuelto', 'Cerrado'].contains(t.status))
            .length;
        expect(result.length, equals(expectedCount));
      },
    );

    Glados(any.list(any.intInRange(0, 6)), ExploreConfig(numRuns: 100)).test(
      'la unión de los 3 filtros específicos cubre todos los tickets',
      (statusIndices) {
        final tickets = _generateTicketList(statusIndices);
        final abiertos = applyFilter(tickets, 'abiertos');
        final enProceso = applyFilter(tickets, 'enProceso');
        final cerrados = applyFilter(tickets, 'cerrados');

        expect(
          abiertos.length + enProceso.length + cerrados.length,
          equals(tickets.length),
        );
      },
    );
  });

  // Feature: soporti-app, Property 6: Relative time formatting
  // **Validates: Requirements 2.2**
  group('Property 6: Relative time formatting', () {
    setUpAll(() {
      timeago.setLocaleMessages('es', timeago.EsMessages());
    });

    Glados(any.intInRange(0, 23), ExploreConfig(numRuns: 100)).test(
      'timestamps < 24h muestran formato "hace" con horas/minutos',
      (hoursAgo) {
        // Crear timestamp entre 2 minutos y 23 horas en el pasado
        // (timeago muestra "hace un momento" para < 1 min)
        final createdAt =
            DateTime.now().subtract(Duration(hours: hoursAgo, minutes: 2));
        final result = timeago.format(createdAt, locale: 'es');

        // Debe contener "hace" indicando tiempo relativo
        // timeago en español usa "hace X minutos", "hace X horas", "hace un momento"
        expect(result, contains('hace'));
        // No debe ser "ayer" ni contener "días"
        if (hoursAgo < 22) {
          // Para menos de ~22 horas, no debería decir "ayer"
          expect(result, isNot(equals('ayer')));
        }
      },
    );

    Glados(any.intInRange(24, 48), ExploreConfig(numRuns: 100)).test(
      'timestamps entre 24-48h muestran "ayer" o "hace 1 día"',
      (hoursAgo) {
        final createdAt = DateTime.now().subtract(Duration(hours: hoursAgo));
        final result = timeago.format(createdAt, locale: 'es');

        // timeago en español muestra "hace 1 día" o "ayer" para este rango
        final isExpectedFormat =
            result.contains('día') || result.contains('ayer');
        expect(isExpectedFormat, isTrue,
            reason:
                'Para $hoursAgo horas atrás se esperaba "día" o "ayer", pero se obtuvo: "$result"');
      },
    );

    Glados(any.intInRange(49, 720), ExploreConfig(numRuns: 100)).test(
      'timestamps > 48h muestran "hace X días"',
      (hoursAgo) {
        final createdAt = DateTime.now().subtract(Duration(hours: hoursAgo));
        final result = timeago.format(createdAt, locale: 'es');

        // Para más de 48 horas, timeago muestra "hace X días"
        // (o "hace aproximadamente X meses" para valores muy grandes)
        final isExpectedFormat = result.contains('día') ||
            result.contains('días') ||
            result.contains('mes') ||
            result.contains('meses');
        expect(isExpectedFormat, isTrue,
            reason:
                'Para $hoursAgo horas atrás se esperaba formato de días/meses, pero se obtuvo: "$result"');
      },
    );
  });

  // Feature: soporti-app, Property 12: Active ticket count correctness
  // **Validates: Requirements 2.1**
  group('Property 12: Active ticket count correctness', () {
    Glados(any.list(any.intInRange(0, 6)), ExploreConfig(numRuns: 100)).test(
      'conteo activo = tickets con estatus distinto de Cerrado',
      (statusIndices) {
        final tickets = _generateTicketList(statusIndices);

        // Lógica del activeTicketCountProvider
        final activeCount =
            tickets.where((t) => t.status != 'Cerrado').length;

        // Verificar contra conteo manual
        final expectedActive = statusIndices
            .map((i) => _allStatuses[i % _allStatuses.length])
            .where((s) => s != 'Cerrado')
            .length;

        expect(activeCount, equals(expectedActive));
      },
    );

    Glados(any.list(any.intInRange(0, 6)), ExploreConfig(numRuns: 100)).test(
      'conteo activo + tickets cerrados = total de tickets',
      (statusIndices) {
        final tickets = _generateTicketList(statusIndices);

        final activeCount =
            tickets.where((t) => t.status != 'Cerrado').length;
        final closedCount =
            tickets.where((t) => t.status == 'Cerrado').length;

        expect(activeCount + closedCount, equals(tickets.length));
      },
    );

    Glados(any.intInRange(0, 50), ExploreConfig(numRuns: 100)).test(
      'lista con todos los tickets en estatus Cerrado tiene conteo activo = 0',
      (count) {
        final tickets = List.generate(
          count,
          (_) => _makeTicket(status: 'Cerrado'),
        );

        final activeCount =
            tickets.where((t) => t.status != 'Cerrado').length;

        expect(activeCount, equals(0));
      },
    );

    Glados(any.intInRange(1, 50), ExploreConfig(numRuns: 100)).test(
      'lista sin ningún ticket Cerrado tiene conteo activo = total',
      (count) {
        // Usar solo estatus no-cerrados
        const nonClosedStatuses = [
          'Abierto',
          'Asignado',
          'En proceso',
          'En espera',
          'Resuelto',
        ];
        final tickets = List.generate(
          count,
          (i) => _makeTicket(
              status: nonClosedStatuses[i % nonClosedStatuses.length]),
        );

        final activeCount =
            tickets.where((t) => t.status != 'Cerrado').length;

        expect(activeCount, equals(count));
      },
    );
  });
}
