import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../models/profile.dart';
import '../../../models/ticket.dart';
import '../../../models/ticket_event.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/tech_repository.dart';

/// Provider que obtiene la cola de tickets asignados al técnico actual.
/// Ordenados por tiempo restante ascendente (mayor urgencia primero).
final techQueueProvider = FutureProvider<List<Ticket>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];

  final repository = ref.watch(techRepositoryProvider);
  final tickets = await repository.getAssignedTickets(user.id);

  // Ordenar por tiempo restante ascendente (mayor urgencia primero)
  tickets.sort((a, b) => a.timeRemaining.compareTo(b.timeRemaining));

  return tickets;
});

/// Provider que obtiene los tickets disponibles (sin asignar).
final availableTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final repository = ref.watch(techRepositoryProvider);
  return repository.getAvailableTickets();
});

/// Provider con el conteo de tickets por prioridad en la cola del técnico.
/// Retorna un Map con las claves: 'Crítica', 'Alta', 'Media', 'Baja'.
final priorityBadgeCountProvider =
    Provider<AsyncValue<Map<String, int>>>((ref) {
  final queueAsync = ref.watch(techQueueProvider);

  return queueAsync.whenData((tickets) {
    final counts = <String, int>{
      'Crítica': 0,
      'Alta': 0,
      'Media': 0,
      'Baja': 0,
    };

    for (final ticket in tickets) {
      if (counts.containsKey(ticket.priority)) {
        counts[ticket.priority] = counts[ticket.priority]! + 1;
      }
    }

    return counts;
  });
});

/// Provider con el total de tickets en la cola del técnico.
final techQueueCountProvider = Provider<AsyncValue<int>>((ref) {
  final queueAsync = ref.watch(techQueueProvider);
  return queueAsync.whenData((tickets) => tickets.length);
});

/// Provider family que obtiene un ticket por su ID (para la vista técnico).
final techTicketByIdProvider =
    FutureProvider.family<Ticket, String>((ref, ticketId) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final response = await client
        .from('tickets')
        .select()
        .eq('id', ticketId)
        .single();
    return Ticket.fromJson(response);
  } on PostgrestException catch (e) {
    throw NotFoundException('Ticket no encontrado: ${e.message}');
  } catch (e) {
    throw const NetworkException();
  }
});

/// Provider family que obtiene TODOS los eventos de un ticket (incluidos internos).
/// Para uso del técnico que tiene visibilidad completa.
/// Los eventos se ordenan por created_at ascendente (cronológico).
final techTicketEventsProvider =
    FutureProvider.family<List<TicketEvent>, String>((ref, ticketId) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final response = await client
        .from('ticket_events')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((json) => TicketEvent.fromJson(json as Map<String, dynamic>))
        .toList();
  } on PostgrestException catch (e) {
    throw NotFoundException('Error al obtener eventos: ${e.message}');
  } catch (e) {
    throw const NetworkException();
  }
});


/// Provider que obtiene la lista de todos los técnicos disponibles para reasignación.
/// Excluye al técnico actualmente autenticado.
final availableTechniciansProvider =
    FutureProvider.family<List<Profile>, String?>((ref, excludeId) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    var query = client.from('profiles').select().eq('role', 'tecnico');

    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }

    final response = await query.order('full_name', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Profile.fromJson(json as Map<String, dynamic>))
        .toList();
  } on PostgrestException catch (e) {
    throw NotFoundException('Error al obtener técnicos: ${e.message}');
  } catch (e) {
    throw const NetworkException();
  }
});
