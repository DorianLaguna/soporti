import 'package:glados/glados.dart';
import 'package:test/test.dart';

import 'package:soporti/models/ticket_event.dart';

// Feature: soporti-app, Property 14: Internal events visibility restriction
// **Validates: Requirements 6.4**

// ============================================================
// Helper: filtra eventos para la vista del solicitante.
// Replica la lógica de filtrado de TicketEventRepository.getEventsForTicket():
// solo retorna eventos donde is_internal == false.
// ============================================================

/// Filtra eventos para la vista del solicitante: solo eventos no-internos.
/// Esta función replica la lógica de query:
/// `.eq('is_internal', false)` en ticket_events_provider.dart
List<TicketEvent> filterEventsForSolicitante(List<TicketEvent> events) {
  return events.where((event) => !event.isInternal).toList();
}

// ============================================================
// Generadores de datos de prueba.
// ============================================================

/// Crea un TicketEvent con valores controlados.
TicketEvent _makeEvent({
  required bool isInternal,
  String? id,
  String ticketId = 'ticket-001',
  String eventType = 'status_change',
  String description = 'Evento de prueba',
  String createdBy = 'user-001',
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime.now();
  return TicketEvent(
    id: id ?? 'event-${now.microsecondsSinceEpoch}-${isInternal ? 'int' : 'pub'}',
    ticketId: ticketId,
    eventType: eventType,
    description: description,
    isInternal: isInternal,
    createdBy: createdBy,
    createdAt: now,
  );
}

/// Genera una lista de eventos con valores is_internal basados en una lista de bools.
List<TicketEvent> _makeEventList(List<bool> internalFlags) {
  final base = DateTime(2024, 6, 1, 10, 0, 0);
  return internalFlags.asMap().entries.map((entry) {
    final i = entry.key;
    final isInternal = entry.value;
    return _makeEvent(
      isInternal: isInternal,
      id: 'event-$i',
      createdAt: base.add(Duration(minutes: i * 5)),
    );
  }).toList();
}

void main() {
  // Feature: soporti-app, Property 14: Internal events visibility restriction
  // **Validates: Requirements 6.4**
  group('Property 14: Internal events visibility restriction', () {
    Glados(any.list(any.bool), ExploreConfig(numRuns: 100)).test(
      'ningún evento interno aparece en la vista del solicitante',
      (internalFlags) {
        final events = _makeEventList(internalFlags);
        final filtered = filterEventsForSolicitante(events);

        for (final event in filtered) {
          expect(event.isInternal, isFalse,
              reason: 'Evento "${event.id}" con isInternal=true '
                  'no debe ser visible para el solicitante');
        }
      },
    );

    Glados(any.list(any.bool), ExploreConfig(numRuns: 100)).test(
      'todos los eventos no-internos del input están presentes en el resultado',
      (internalFlags) {
        final events = _makeEventList(internalFlags);
        final filtered = filterEventsForSolicitante(events);

        final expectedPublicEvents =
            events.where((e) => !e.isInternal).toList();

        // Cada evento no-interno del input debe estar en el resultado
        for (final expected in expectedPublicEvents) {
          final found = filtered.any((e) => e.id == expected.id);
          expect(found, isTrue,
              reason: 'Evento público "${expected.id}" debe estar '
                  'presente en la vista del solicitante');
        }
      },
    );

    Glados(any.list(any.bool), ExploreConfig(numRuns: 100)).test(
      'conteo de eventos filtrados == conteo de eventos donde is_internal == false',
      (internalFlags) {
        final events = _makeEventList(internalFlags);
        final filtered = filterEventsForSolicitante(events);

        final expectedCount = internalFlags.where((f) => !f).length;

        expect(filtered.length, equals(expectedCount),
            reason: 'Cantidad de eventos filtrados (${filtered.length}) '
                'debe ser igual a la cantidad de eventos no-internos '
                '($expectedCount) en el input');
      },
    );

    Glados(any.intInRange(1, 20), ExploreConfig(numRuns: 100)).test(
      'una lista con SOLO eventos internos produce resultado vacío',
      (count) {
        // Generar una lista donde todos los flags son true (interno)
        final allInternalFlags = List.filled(count, true);
        final events = _makeEventList(allInternalFlags);
        final filtered = filterEventsForSolicitante(events);

        expect(filtered, isEmpty,
            reason: 'Si todos los eventos son internos, '
                'el solicitante no debe ver ninguno');
      },
    );

    Glados(any.intInRange(1, 20), ExploreConfig(numRuns: 100)).test(
      'una lista con SOLO eventos públicos se preserva completa',
      (count) {
        // Generar una lista donde todos los flags son false (público)
        final allPublicFlags = List.filled(count, false);
        final events = _makeEventList(allPublicFlags);
        final filtered = filterEventsForSolicitante(events);

        expect(filtered.length, equals(count),
            reason: 'Si todos los eventos son públicos, '
                'el solicitante debe ver todos ($count)');

        // Verificar que los IDs coinciden
        for (int i = 0; i < count; i++) {
          expect(filtered[i].id, equals(events[i].id));
        }
      },
    );
  });
}
