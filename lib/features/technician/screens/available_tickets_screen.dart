import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/priority_chip.dart';
import '../../../models/ticket.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tickets/providers/ticket_provider.dart';
import '../providers/tech_provider.dart';
import '../repositories/tech_repository.dart';

/// Pantalla que muestra los tickets disponibles (sin asignar) para que
/// el técnico pueda auto-asignarse uno.
///
/// Muestra tickets con estatus 'Abierto' y assigned_to IS NULL.
/// Cada ticket tiene un botón "Asignarme" para auto-asignación.
class AvailableTicketsScreen extends ConsumerWidget {
  const AvailableTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(availableTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.availableTickets),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ticketsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.error,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(availableTicketsProvider),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay tickets disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(availableTicketsProvider);
              await ref.read(availableTicketsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return _AvailableTicketCard(ticket: ticket);
              },
            ),
          );
        },
      ),
    );
  }
}

/// Card simplificada para un ticket disponible.
/// Muestra código, título, chip de categoría, chip de prioridad y botón "Asignarme".
class _AvailableTicketCard extends ConsumerWidget {
  final Ticket ticket;

  const _AvailableTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColor = AppColors.priorityColor(ticket.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Borde izquierdo coloreado por prioridad
            Container(
              width: 4,
              color: priorityColor,
            ),
            // Contenido del card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Código del ticket
                    Text(
                      ticket.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Título truncado
                    Text(
                      ticket.truncatedTitle,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Fila: chips de categoría y prioridad
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            ticket.category,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          backgroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: AppColors.divider),
                        ),
                        const SizedBox(width: 8),
                        PriorityChip(priority: ticket.priority),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Botón "Asignarme"
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => _assignToSelf(context, ref),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text(AppStrings.assignToMe),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ejecuta la auto-asignación del ticket al técnico actual.
  Future<void> _assignToSelf(BuildContext context, WidgetRef ref) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    try {
      final repository = ref.read(techRepositoryProvider);
      await repository.assignToSelf(ticket.id, user.id);

      // Refrescar la lista de tickets disponibles y la cola del técnico
      // (el ticket recién asignado debe aparecer ahí de inmediato), y la
      // lista del solicitante (ya no está "Abierto" sino "Asignado").
      ref.invalidate(availableTicketsProvider);
      ref.invalidate(techQueueProvider);
      ref.invalidate(userTicketsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket ${ticket.code} asignado exitosamente'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar ticket: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
