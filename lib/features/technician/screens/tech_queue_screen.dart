import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/priority_chip.dart';
import '../../../models/ticket.dart';
import '../providers/tech_provider.dart';

/// Pantalla principal del técnico que muestra su cola de tickets asignados.
///
/// Incluye:
/// - Encabezado "Mi cola" con badges contadores por prioridad
/// - Lista de tickets ordenada por urgencia (tiempo restante ascendente)
/// - Indicador de tiempo en rojo si < 2 horas
/// - Swipe izquierdo para revelar "Cambiar estatus"
/// - Estado vacío cuando no hay tickets
/// - BottomNavigationBar: Mi cola, Disponibles, Perfil
/// - Pull-to-refresh
class TechQueueScreen extends ConsumerWidget {
  const TechQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(techQueueProvider);
    final badgeCountAsync = ref.watch(priorityBadgeCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.techQueue),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Encabezado con badges de prioridad
          _PriorityBadgesHeader(badgeCountAsync: badgeCountAsync),
          // Lista de tickets
          Expanded(
            child: queueAsync.when(
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
                      onPressed: () => ref.invalidate(techQueueProvider),
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
              data: (tickets) {
                if (tickets.isEmpty) {
                  return const _EmptyQueueState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(techQueueProvider);
                    await ref.read(techQueueProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return _SwipeableTicketCard(ticket: ticket);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) => _onNavTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: AppStrings.navQueue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: AppStrings.navAvailable,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.navProfile,
          ),
        ],
      ),
    );
  }

  /// Maneja la navegación al tocar un tab del BottomNavigationBar.
  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Ya estamos en Mi cola
        break;
      case 1:
        context.push('/available');
        break;
      case 2:
        context.push('/profile');
        break;
    }
  }
}

/// Encabezado con badges contadores por prioridad.
/// Muestra pequeños badges coloreados con el conteo de tickets
/// por cada nivel de prioridad.
class _PriorityBadgesHeader extends StatelessWidget {
  final AsyncValue<Map<String, int>> badgeCountAsync;

  const _PriorityBadgesHeader({required this.badgeCountAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surfaceCard,
      child: badgeCountAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (counts) {
          return Row(
            children: [
              _PriorityBadge(
                label: AppStrings.priorityCritica,
                count: counts['Crítica'] ?? 0,
                color: AppColors.priorityCritica,
              ),
              const SizedBox(width: 8),
              _PriorityBadge(
                label: AppStrings.priorityAlta,
                count: counts['Alta'] ?? 0,
                color: AppColors.priorityAlta,
              ),
              const SizedBox(width: 8),
              _PriorityBadge(
                label: AppStrings.priorityMedia,
                count: counts['Media'] ?? 0,
                color: AppColors.priorityMedia,
              ),
              const SizedBox(width: 8),
              _PriorityBadge(
                label: AppStrings.priorityBaja,
                count: counts['Baja'] ?? 0,
                color: AppColors.priorityBaja,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Badge individual que muestra la prioridad con su color y conteo.
class _PriorityBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _PriorityBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de ticket con swipe-to-action para "Cambiar estatus".
/// Usa Dismissible con dirección endToStart para revelar la acción.
class _SwipeableTicketCard extends StatelessWidget {
  final Ticket ticket;

  const _SwipeableTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppColors.priorityColor(ticket.priority);
    final remaining = ticket.timeRemaining;
    final isUrgent = remaining.inHours < 2 && !remaining.isNegative;
    final timeColor =
        (isUrgent || ticket.isSlaBreached) ? AppColors.slaWarning : AppColors.textSecondary;

    return Dismissible(
      key: ValueKey(ticket.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Navegar a detalle/cambiar estatus sin remover el item
        context.push('/queue/${ticket.id}');
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.edit_note, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              AppStrings.changeStatus,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      child: Card(
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
                      // Primera fila: código y tiempo restante
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ticket.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            ticket.isSlaBreached
                                ? AppStrings.slaBreached
                                : '${remaining.inHours} ${AppStrings.hoursRemaining}',
                            style: TextStyle(
                              color: timeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Categoría
                      Text(
                        ticket.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Título truncado
                      Text(
                        ticket.truncatedTitle,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Chips: prioridad y ubicación
                      Row(
                        children: [
                          PriorityChip(priority: ticket.priority),
                          if (ticket.location.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Chip(
                                avatar: const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                label: Text(
                                  ticket.location,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado vacío que se muestra cuando el técnico no tiene tickets asignados.
class _EmptyQueueState extends StatelessWidget {
  const _EmptyQueueState();

  @override
  Widget build(BuildContext context) {
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
            AppStrings.emptyQueue,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
