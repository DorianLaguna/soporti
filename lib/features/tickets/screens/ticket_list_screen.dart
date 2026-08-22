import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/ticket_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/ticket_provider.dart';

/// Pantalla principal del solicitante — lista de tickets con filtros.
///
/// Muestra:
/// - Saludo "Hola, [nombre]"
/// - Título "Mis tickets" con conteo de activos
/// - Chips de filtro (Todos, Abiertos, En proceso, Cerrados)
/// - Lista scrollable de TicketCards
/// - Estado vacío cuando no hay tickets para el filtro
/// - FAB "+" para crear ticket
/// - BottomNavigationBar: Mis tickets, Nuevo, Perfil
class TicketListScreen extends ConsumerWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final filteredTicketsAsync = ref.watch(filteredTicketsProvider);
    final activeCountAsync = ref.watch(activeTicketCountProvider);
    final currentFilter = ref.watch(ticketFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: Saludo + Mis tickets + conteo ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: userAsync.when(
                data: (profile) {
                  final name = profile?.fullName ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppStrings.greeting}$name',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            AppStrings.myTickets,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(width: 8),
                          activeCountAsync.when(
                            data: (count) => Text(
                              '$count ${AppStrings.activeTickets}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text(
                  AppStrings.error,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Chips de filtro ───────────────────────────────────────
            _FilterChipsRow(currentFilter: currentFilter, ref: ref),
            const SizedBox(height: 8),

            // ─── Lista de tickets ──────────────────────────────────────
            Expanded(
              child: filteredTicketsAsync.when(
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return _EmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(userTicketsProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return TicketCard(
                          ticket: ticket,
                          onTap: () {
                            context.push('/tickets/${ticket.id}');
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => _ErrorState(
                  onRetry: () {
                    ref.invalidate(userTicketsProvider);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tickets/create'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Ya estamos en Mis tickets
              break;
            case 1:
              context.push('/tickets/create');
              break;
            case 2:
              context.push('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: AppStrings.navMyTickets,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: AppStrings.navNew,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.navProfile,
          ),
        ],
      ),
    );
  }
}

/// Fila de chips de filtro scrollable horizontalmente.
class _FilterChipsRow extends StatelessWidget {
  final TicketFilter currentFilter;
  final WidgetRef ref;

  const _FilterChipsRow({required this.currentFilter, required this.ref});

  @override
  Widget build(BuildContext context) {
    final filters = [
      (TicketFilter.todos, AppStrings.filterAll),
      (TicketFilter.abiertos, AppStrings.filterOpen),
      (TicketFilter.enProceso, AppStrings.filterInProgress),
      (TicketFilter.cerrados, AppStrings.filterClosed),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((entry) {
          final (filter, label) = entry;
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                ref.read(ticketFilterProvider.notifier).state = filter;
              },
              selectedColor: AppColors.uvmGreen.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.uvmGreen : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget de estado vacío cuando no hay tickets para el filtro.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.emptyTickets,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de estado de error con botón de reintentar.
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.error,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
