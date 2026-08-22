import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/priority_chip.dart';
import '../../../core/widgets/timeline_event.dart';
import '../../../models/ticket.dart';
import '../providers/ticket_events_provider.dart';
import '../repositories/ticket_repository.dart';
import '../widgets/rating_section.dart';

/// Provider family que obtiene un ticket por su ID.
final ticketByIdProvider =
    FutureProvider.family<Ticket, String>((ref, ticketId) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getTicketById(ticketId);
});

/// Pantalla de detalle de ticket para el solicitante.
///
/// Muestra:
/// - Código SOP-XXXX (grande, bold)
/// - Título del ticket
/// - Row con PriorityChip + SLA time restante
/// - Chip de categoría
/// - Línea de tiempo con eventos ordenados cronológicamente (ascendente)
/// - Eventos internos NO se muestran (filtrado en el provider)
class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketByIdProvider(ticketId));
    final eventsAsync = ref.watch(ticketEventsProvider(ticketId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.ticketDetail),
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                AppStrings.error,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(ticketByIdProvider(ticketId)),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
        data: (ticket) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header: Código SOP-XXXX ─────────────────────────
              Text(
                ticket.code,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // ─── Título ──────────────────────────────────────────
              Text(
                ticket.title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // ─── Row: PriorityChip + SLA restante ────────────────
              Row(
                children: [
                  PriorityChip(priority: ticket.priority),
                  const SizedBox(width: 8),
                  _SlaIndicator(ticket: ticket),
                ],
              ),
              const SizedBox(height: 8),

              // ─── Chip de categoría ───────────────────────────────
              Chip(
                label: Text(
                  ticket.category,
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(height: 24),

              // ─── Línea de tiempo ─────────────────────────────────
              Text(
                AppStrings.timeline,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _TimelineSection(eventsAsync: eventsAsync, ticketId: ticketId, ref: ref),

              // ─── Sección de calificación (solo visible en estatus Resuelto) ───
              if (ticket.status == 'Resuelto')
                RatingSection(ticketId: ticketId),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador de SLA restante con color según urgencia.
class _SlaIndicator extends StatelessWidget {
  final Ticket ticket;

  const _SlaIndicator({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isBreached = ticket.isSlaBreached;
    final displayText = ticket.displayTimeRemaining;
    final textColor = isBreached ? AppColors.slaWarning : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isBreached ? Icons.warning_amber_rounded : Icons.schedule,
          size: 16,
          color: textColor,
        ),
        const SizedBox(width: 4),
        Text(
          displayText,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: isBreached ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Sección de la línea de tiempo con manejo de estados async.
class _TimelineSection extends StatelessWidget {
  final AsyncValue eventsAsync;
  final String ticketId;
  final WidgetRef ref;

  const _TimelineSection({
    required this.eventsAsync,
    required this.ticketId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return eventsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Column(
        children: [
          Text(
            AppStrings.error,
            style: TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(ticketEventsProvider(ticketId)),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
      data: (events) {
        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay eventos registrados',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return Column(
          children: List.generate(events.length, (index) {
            return TimelineEventWidget(
              event: events[index],
              isLast: index == events.length - 1,
            );
          }),
        );
      },
    );
  }
}
