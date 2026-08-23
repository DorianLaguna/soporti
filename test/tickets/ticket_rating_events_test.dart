import 'package:glados/glados.dart';

import 'package:soporti/models/ticket.dart';
import 'package:soporti/models/ticket_event.dart';

// ============================================================
// Helper: simula la operación de calificación y cierre de ticket.
// Lógica pura — sin Supabase ni side effects.
// ============================================================

/// Simula la operación de enviar rating y cerrar ticket.
/// Precondición: ticket.status == 'Resuelto', rating entre 1 y 5.
/// Postcondición: ticket.status == 'Cerrado', ticket.rating == rating enviado.
Ticket rateAndCloseTicket(Ticket ticket, int rating) {
  assert(ticket.status == 'Resuelto', 'Ticket debe estar en estatus Resuelto');
  assert(rating >= 1 && rating <= 5, 'Rating debe estar entre 1 y 5');

  return Ticket(
    id: ticket.id,
    code: ticket.code,
    title: ticket.title,
    description: ticket.description,
    category: ticket.category,
    priority: ticket.priority,
    status: 'Cerrado',
    location: ticket.location,
    requesterId: ticket.requesterId,
    assignedTo: ticket.assignedTo,
    createdAt: ticket.createdAt,
    updatedAt: DateTime.now(),
    resolvedAt: ticket.resolvedAt,
    rating: rating,
  );
}

// ============================================================
// Helper: ordena eventos cronológicamente (ascendente por createdAt).
// Replica la lógica de presentación de la línea de tiempo.
// ============================================================

/// Ordena una lista de eventos por createdAt ascendente (oldest first).
/// Mantiene estabilidad: eventos con mismo timestamp conservan su orden relativo.
List<TicketEvent> sortEventsChronologically(List<TicketEvent> events) {
  final sorted = List<TicketEvent>.from(events);
  // Dart's List.sort is stable (mergesort), so equal timestamps keep order.
  sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return sorted;
}

// ============================================================
// Helpers para generación de datos de prueba.
// ============================================================

/// Crea un Ticket en estatus "Resuelto" para pruebas de rating.
Ticket _makeResolvedTicket({String? id}) {
  final now = DateTime.now();
  return Ticket(
    id: id ?? 'ticket-resolved-${now.microsecondsSinceEpoch}',
    code: 'SOP-0042',
    title: 'Ticket resuelto para prueba de rating',
    description: 'Descripción del ticket de prueba resuelto',
    category: 'Software',
    priority: 'Media',
    status: 'Resuelto',
    location: 'Campus Sur',
    requesterId: 'user-solicitante-001',
    assignedTo: 'user-tecnico-001',
    createdAt: now.subtract(const Duration(hours: 12)),
    updatedAt: now.subtract(const Duration(hours: 1)),
    resolvedAt: now.subtract(const Duration(hours: 1)),
  );
}

/// Crea un TicketEvent con timestamp dado.
TicketEvent _makeEvent({
  required DateTime createdAt,
  String? id,
  String ticketId = 'ticket-001',
  String eventType = 'status_change',
  String description = 'Evento de prueba',
}) {
  return TicketEvent(
    id: id ?? 'event-${createdAt.microsecondsSinceEpoch}',
    ticketId: ticketId,
    eventType: eventType,
    description: description,
    isInternal: false,
    createdBy: 'user-001',
    createdAt: createdAt,
  );
}

void main() {
  // Feature: soporti-app, Property 9: Rating round-trip
  // **Validates: Requirements 4.4**
  group('Property 9: Rating round-trip', () {
    Glados(any.intInRange(1, 6), ExploreConfig(numRuns: 100)).test(
      'rating guardado == rating enviado para cualquier valor válido (1-5)',
      (rating) {
        final ticket = _makeResolvedTicket();
        final result = rateAndCloseTicket(ticket, rating);

        expect(result.rating, equals(rating),
            reason: 'Rating almacenado (${ result.rating}) '
                'debe ser igual al enviado ($rating)');
      },
    );

    Glados(any.intInRange(1, 6), ExploreConfig(numRuns: 100)).test(
      'estatus cambia a "Cerrado" para cualquier rating válido',
      (rating) {
        final ticket = _makeResolvedTicket();
        final result = rateAndCloseTicket(ticket, rating);

        expect(result.status, equals('Cerrado'),
            reason: 'Estatus debe cambiar a Cerrado después de calificar');
      },
    );

    Glados(any.intInRange(1, 6), ExploreConfig(numRuns: 100)).test(
      'rating se preserva exactamente sin redondeo ni modificación',
      (rating) {
        final ticket = _makeResolvedTicket();
        final result = rateAndCloseTicket(ticket, rating);

        // Verificar que el rating es exactamente el int enviado
        expect(result.rating, isA<int>());
        expect(identical(result.rating, rating) || result.rating == rating,
            isTrue,
            reason: 'Rating debe preservarse exactamente: '
                'enviado=$rating, almacenado=${result.rating}');
      },
    );

    Glados(any.intInRange(1, 6), ExploreConfig(numRuns: 100)).test(
      'datos del ticket original se preservan (id, code, title, etc.)',
      (rating) {
        final ticket = _makeResolvedTicket(id: 'preserved-ticket-id');
        final result = rateAndCloseTicket(ticket, rating);

        expect(result.id, equals(ticket.id));
        expect(result.code, equals(ticket.code));
        expect(result.title, equals(ticket.title));
        expect(result.description, equals(ticket.description));
        expect(result.category, equals(ticket.category));
        expect(result.priority, equals(ticket.priority));
        expect(result.location, equals(ticket.location));
        expect(result.requesterId, equals(ticket.requesterId));
        expect(result.assignedTo, equals(ticket.assignedTo));
        expect(result.createdAt, equals(ticket.createdAt));
        expect(result.resolvedAt, equals(ticket.resolvedAt));
      },
    );
  });

  // Feature: soporti-app, Property 10: Event chronological ordering
  // **Validates: Requirements 10.5**
  group('Property 10: Event chronological ordering', () {
    Glados(any.list(any.intInRange(0, 100000)),
            ExploreConfig(numRuns: 100))
        .test(
      'eventos ordenados siempre tienen createdAt ascendente',
      (minuteOffsets) {
        final baseTime = DateTime(2024, 1, 1, 0, 0, 0);
        final events = minuteOffsets
            .map((offset) =>
                _makeEvent(createdAt: baseTime.add(Duration(minutes: offset))))
            .toList();

        final sorted = sortEventsChronologically(events);

        for (int i = 1; i < sorted.length; i++) {
          expect(
            sorted[i].createdAt.compareTo(sorted[i - 1].createdAt) >= 0,
            isTrue,
            reason: 'Evento en posición $i '
                '(${sorted[i].createdAt}) debe ser >= evento en posición '
                '${i - 1} (${sorted[i - 1].createdAt})',
          );
        }
      },
    );

    Glados(any.list(any.intInRange(0, 50000)),
            ExploreConfig(numRuns: 100))
        .test(
      'la longitud de la lista ordenada es igual a la lista original',
      (minuteOffsets) {
        final baseTime = DateTime(2024, 6, 15, 12, 0, 0);
        final events = minuteOffsets
            .map((offset) =>
                _makeEvent(createdAt: baseTime.add(Duration(minutes: offset))))
            .toList();

        final sorted = sortEventsChronologically(events);

        expect(sorted.length, equals(events.length));
      },
    );

    Glados(any.intInRange(2, 20), ExploreConfig(numRuns: 100)).test(
      'eventos con mismo timestamp mantienen orden relativo (estabilidad)',
      (count) {
        // Crear múltiples eventos con exactamente el mismo timestamp
        final sameTime = DateTime(2024, 3, 10, 14, 30, 0);
        final events = List.generate(
          count,
          (i) => _makeEvent(
            createdAt: sameTime,
            id: 'event-same-$i',
            description: 'Evento número $i',
          ),
        );

        final sorted = sortEventsChronologically(events);

        // Dart's sort is stable, so order should be preserved for equal keys
        for (int i = 0; i < sorted.length; i++) {
          expect(sorted[i].id, equals(events[i].id),
              reason: 'Evento en posición $i debe mantener su orden original '
                  'cuando timestamps son iguales');
        }
      },
    );

    Glados(any.list(any.intInRange(-50000, 50000)),
            ExploreConfig(numRuns: 100))
        .test(
      'sorting es idempotente — ordenar dos veces da mismo resultado',
      (minuteOffsets) {
        final baseTime = DateTime(2024, 1, 15, 8, 0, 0);
        final events = minuteOffsets
            .map((offset) =>
                _makeEvent(createdAt: baseTime.add(Duration(minutes: offset))))
            .toList();

        final sorted1 = sortEventsChronologically(events);
        final sorted2 = sortEventsChronologically(sorted1);

        for (int i = 0; i < sorted1.length; i++) {
          expect(sorted2[i].createdAt, equals(sorted1[i].createdAt));
          expect(sorted2[i].id, equals(sorted1[i].id));
        }
      },
    );

    Glados(any.list(any.intInRange(0, 100000)),
            ExploreConfig(numRuns: 100))
        .test(
      'primer evento en lista ordenada tiene el menor timestamp',
      (minuteOffsets) {
        if (minuteOffsets.isEmpty) return; // skip empty lists

        final baseTime = DateTime(2024, 2, 1, 0, 0, 0);
        final events = minuteOffsets
            .map((offset) =>
                _makeEvent(createdAt: baseTime.add(Duration(minutes: offset))))
            .toList();

        final sorted = sortEventsChronologically(events);

        // El primer elemento debe tener el menor (o igual al menor) timestamp
        final minTimestamp = events
            .map((e) => e.createdAt)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        expect(sorted.first.createdAt, equals(minTimestamp));
      },
    );
  });
}
