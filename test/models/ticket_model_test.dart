import 'package:glados/glados.dart';
import 'package:soporti/models/ticket.dart';

/// Helper para crear un Ticket con valores por defecto.
Ticket _makeTicket({
  String priority = 'Media',
  String title = 'Título de prueba',
  DateTime? createdAt,
}) {
  final now = DateTime.now();
  return Ticket(
    id: 'test-id',
    code: 'SOP-0001',
    title: title,
    description: 'Descripción de prueba para el ticket',
    category: 'Software',
    priority: priority,
    status: 'Abierto',
    location: 'Campus Norte',
    requesterId: 'user-001',
    createdAt: createdAt ?? now,
    updatedAt: now,
  );
}

/// Prioridades válidas del sistema.
const _priorities = ['Crítica', 'Alta', 'Media', 'Baja'];

/// Mapeo esperado prioridad → duración SLA.
const _expectedSla = {
  'Crítica': Duration(hours: 4),
  'Alta': Duration(hours: 8),
  'Media': Duration(hours: 24),
  'Baja': Duration(hours: 48),
};

void main() {
  // Feature: soporti-app, Property 2: SLA time mapping correctness
  // **Validates: Requirements 12.1–12.4**
  group('Property 2: SLA time mapping correctness', () {
    Glados(any.intInRange(0, 4), ExploreConfig(numRuns: 100)).test(
      'cada prioridad mapea a su duración SLA exacta',
      (index) {
        final priority = _priorities[index];
        final ticket = _makeTicket(priority: priority);

        expect(ticket.slaLimit, equals(_expectedSla[priority]));
      },
    );

    test('prioridades cubren exactamente los 4 valores definidos', () {
      for (final entry in _expectedSla.entries) {
        final ticket = _makeTicket(priority: entry.key);
        expect(ticket.slaLimit, equals(entry.value),
            reason: 'SLA para ${entry.key} debería ser ${entry.value}');
      }
    });

    test('prioridad desconocida tiene fallback a 24h', () {
      final ticket = _makeTicket(priority: 'Inexistente');
      expect(ticket.slaLimit, equals(const Duration(hours: 24)));
    });
  });

  // Feature: soporti-app, Property 3: SLA remaining time calculation
  // **Validates: Requirements 12.5**
  group('Property 3: SLA remaining time calculation', () {
    Glados2(any.intInRange(0, 4), any.intInRange(0, 100),
            ExploreConfig(numRuns: 100))
        .test(
      'timeRemaining = slaLimit - elapsed para cualquier ticket',
      (priorityIndex, hoursAgo) {
        final priority = _priorities[priorityIndex];
        final createdAt = DateTime.now().subtract(Duration(hours: hoursAgo));
        final ticket = _makeTicket(priority: priority, createdAt: createdAt);

        final elapsed = DateTime.now().difference(createdAt);
        final expectedRemaining = ticket.slaLimit - elapsed;

        // Permitimos 1 segundo de tolerancia por tiempo de ejecución del test
        final diff = (ticket.timeRemaining - expectedRemaining).inSeconds.abs();
        expect(diff, lessThanOrEqualTo(1));
      },
    );

    Glados(any.intInRange(0, 4), ExploreConfig(numRuns: 100)).test(
      'timeRemaining es negativo cuando SLA está vencido',
      (priorityIndex) {
        final priority = _priorities[priorityIndex];
        final slaHours = _expectedSla[priority]!.inHours;
        // Crear ticket con tiempo suficiente para que SLA esté vencido
        final createdAt =
            DateTime.now().subtract(Duration(hours: slaHours + 1));
        final ticket = _makeTicket(priority: priority, createdAt: createdAt);

        expect(ticket.timeRemaining.isNegative, isTrue);
        expect(ticket.isSlaBreached, isTrue);
      },
    );

    Glados(any.intInRange(0, 4), ExploreConfig(numRuns: 100)).test(
      'timeRemaining es positivo cuando ticket está dentro del SLA',
      (priorityIndex) {
        final priority = _priorities[priorityIndex];
        // Ticket recién creado siempre está dentro del SLA
        final ticket = _makeTicket(
          priority: priority,
          createdAt: DateTime.now(),
        );

        expect(ticket.timeRemaining.isNegative, isFalse);
        expect(ticket.isSlaBreached, isFalse);
      },
    );
  });

  // Feature: soporti-app, Property 5: Title truncation correctness
  // **Validates: Requirements 2.2**
  group('Property 5: Title truncation correctness', () {
    Glados(any.letterOrDigits, ExploreConfig(numRuns: 100)).test(
      'título > 50 chars se trunca correctamente, <= 50 permanece igual',
      (title) {
        // Asegurar que no sea vacío para construir ticket válido
        final effectiveTitle = title.isEmpty ? 'x' : title;
        final ticket = _makeTicket(title: effectiveTitle);

        if (effectiveTitle.length > 50) {
          expect(ticket.truncatedTitle,
              equals('${effectiveTitle.substring(0, 50)}...'));
          expect(ticket.truncatedTitle.length, equals(53));
        } else {
          expect(ticket.truncatedTitle, equals(effectiveTitle));
        }
      },
    );

    Glados(any.intInRange(51, 200), ExploreConfig(numRuns: 100)).test(
      'título largo siempre produce exactamente 53 caracteres',
      (length) {
        final title = 'a' * length;
        final ticket = _makeTicket(title: title);

        expect(ticket.truncatedTitle.length, equals(53));
        expect(ticket.truncatedTitle.endsWith('...'), isTrue);
        expect(
          ticket.truncatedTitle.substring(0, 50),
          equals(title.substring(0, 50)),
        );
      },
    );

    Glados(any.intInRange(1, 51), ExploreConfig(numRuns: 100)).test(
      'título <= 50 chars permanece sin cambios',
      (length) {
        final title = 'b' * length;
        final ticket = _makeTicket(title: title);

        expect(ticket.truncatedTitle, equals(title));
      },
    );

    test('título de exactamente 50 caracteres no se trunca', () {
      final title = 'c' * 50;
      final ticket = _makeTicket(title: title);
      expect(ticket.truncatedTitle, equals(title));
    });

    test('título de exactamente 51 caracteres se trunca', () {
      final title = 'd' * 51;
      final ticket = _makeTicket(title: title);
      expect(ticket.truncatedTitle, equals('${'d' * 50}...'));
    });
  });
}
