import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/ticket.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/ticket_repository.dart';

/// Enum para los filtros de la lista de tickets del solicitante.
/// Mapping:
///   todos    → todos los tickets
///   abiertos → estatus in ['Abierto', 'Asignado']
///   enProceso → estatus in ['En proceso', 'En espera']
///   cerrados → estatus in ['Resuelto', 'Cerrado']
enum TicketFilter { todos, abiertos, enProceso, cerrados }

/// Provider para el filtro activo de la lista de tickets.
final ticketFilterProvider = StateProvider<TicketFilter>((ref) {
  return TicketFilter.todos;
});

/// Provider que obtiene la lista completa de tickets del usuario actual.
/// Depende de currentUserProvider para obtener el ID del solicitante.
final userTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final userAsync = await ref.watch(currentUserProvider.future);
  if (userAsync == null) return [];

  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getTicketsByRequester(userAsync.id);
});

/// Provider que retorna la lista filtrada de tickets según el filtro activo.
/// Combina userTicketsProvider y ticketFilterProvider.
final filteredTicketsProvider = Provider<AsyncValue<List<Ticket>>>((ref) {
  final ticketsAsync = ref.watch(userTicketsProvider);
  final filter = ref.watch(ticketFilterProvider);

  return ticketsAsync.whenData((tickets) {
    return _applyFilter(tickets, filter);
  });
});

/// Provider que retorna el conteo de tickets activos.
/// Activos = todos los tickets con estatus distinto de "Cerrado".
final activeTicketCountProvider = Provider<AsyncValue<int>>((ref) {
  final ticketsAsync = ref.watch(userTicketsProvider);

  return ticketsAsync.whenData((tickets) {
    return tickets.where((t) => t.status != 'Cerrado').length;
  });
});

/// Aplica el filtro correspondiente a la lista de tickets.
List<Ticket> _applyFilter(List<Ticket> tickets, TicketFilter filter) {
  return switch (filter) {
    TicketFilter.todos => tickets,
    TicketFilter.abiertos =>
      tickets.where((t) => ['Abierto', 'Asignado'].contains(t.status)).toList(),
    TicketFilter.enProceso =>
      tickets.where((t) => ['En proceso', 'En espera'].contains(t.status)).toList(),
    TicketFilter.cerrados =>
      tickets.where((t) => ['Resuelto', 'Cerrado'].contains(t.status)).toList(),
  };
}
