import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../models/ticket_event.dart';

/// Repositorio para obtener los eventos de un ticket.
class TicketEventRepository {
  final SupabaseClient _client;

  TicketEventRepository(this._client);

  /// Obtiene los eventos no-internos de un ticket, ordenados cronológicamente ascendente.
  /// Este es el view del solicitante: eventos con is_internal = false.
  /// Lanza [NotFoundException] si ocurre un error de base de datos.
  /// Lanza [NetworkException] si hay un error de conexión.
  Future<List<TicketEvent>> getEventsForTicket(String ticketId) async {
    try {
      final response = await _client
          .from('ticket_events')
          .select()
          .eq('ticket_id', ticketId)
          .eq('is_internal', false)
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((json) => TicketEvent.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al obtener eventos: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }
}

/// Provider que expone el repositorio de eventos de ticket.
final ticketEventRepositoryProvider = Provider<TicketEventRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TicketEventRepository(client);
});

/// Provider family que obtiene los eventos de un ticket específico.
/// Filtra eventos internos (solo muestra los no-internos para el solicitante).
/// Los eventos se ordenan por created_at ascendente (cronológico).
final ticketEventsProvider =
    FutureProvider.family<List<TicketEvent>, String>((ref, ticketId) async {
  final repository = ref.watch(ticketEventRepositoryProvider);
  return repository.getEventsForTicket(ticketId);
});
