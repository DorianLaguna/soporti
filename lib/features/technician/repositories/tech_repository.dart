import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../models/ticket.dart';

/// Repositorio que abstrae las operaciones del técnico contra Supabase.
class TechRepository {
  final SupabaseClient _client;

  TechRepository(this._client);

  /// Obtiene los tickets sin asignar (estatus 'Abierto', assigned_to IS NULL).
  /// Ordenados por fecha de creación descendente.
  Future<List<Ticket>> getAvailableTickets() async {
    try {
      final response = await _client
          .from('tickets')
          .select()
          .isFilter('assigned_to', null)
          .eq('status', 'Abierto')
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al obtener tickets disponibles: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }

  /// Obtiene los tickets asignados a un técnico, ordenados por tiempo restante ascendente.
  Future<List<Ticket>> getAssignedTickets(String techId) async {
    try {
      final response = await _client
          .from('tickets')
          .select()
          .eq('assigned_to', techId)
          .inFilter('status', ['Asignado', 'En proceso', 'En espera'])
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al obtener cola de tickets: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }

  /// Auto-asigna un ticket al técnico actual.
  /// Actualiza assigned_to, cambia estatus a 'Asignado' y registra evento de asignación.
  Future<void> assignToSelf(String ticketId, String techId) async {
    try {
      // Actualizar el ticket: assigned_to y status
      await _client.from('tickets').update({
        'assigned_to': techId,
        'status': 'Asignado',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', ticketId);

      // Obtener nombre del técnico para el evento
      final profileResponse = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', techId)
          .single();
      final techName = profileResponse['full_name'] as String;

      // Registrar evento de asignación
      await _client.from('ticket_events').insert({
        'ticket_id': ticketId,
        'event_type': 'assigned',
        'description': 'Asignado a $techName',
        'is_internal': false,
        'created_by': techId,
      });
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al asignar ticket: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }

  /// Actualiza el estatus de un ticket.
  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (newStatus == 'Resuelto') {
        updateData['resolved_at'] = DateTime.now().toUtc().toIso8601String();
      }

      await _client.from('tickets').update(updateData).eq('id', ticketId);
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al actualizar estatus: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }

  /// Reasigna un ticket a otro técnico.
  Future<void> reassignTicket(String ticketId, String newTechId) async {
    try {
      await _client.from('tickets').update({
        'assigned_to': newTechId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', ticketId);

      // Obtener nombre del nuevo técnico
      final profileResponse = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', newTechId)
          .single();
      final techName = profileResponse['full_name'] as String;

      final currentUserId = _client.auth.currentUser!.id;

      // Registrar evento de reasignación
      await _client.from('ticket_events').insert({
        'ticket_id': ticketId,
        'event_type': 'assigned',
        'description': 'Reasignado a $techName',
        'is_internal': false,
        'created_by': currentUserId,
      });
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al reasignar ticket: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }

  /// Agrega un evento a la línea de tiempo del ticket.
  Future<void> addEvent({
    required String ticketId,
    required String eventType,
    required String description,
    required String createdBy,
    bool isInternal = false,
  }) async {
    try {
      await _client.from('ticket_events').insert({
        'ticket_id': ticketId,
        'event_type': eventType,
        'description': description,
        'is_internal': isInternal,
        'created_by': createdBy,
      });
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al registrar evento: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }
}

/// Provider que expone el repositorio del técnico.
final techRepositoryProvider = Provider<TechRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TechRepository(client);
});
