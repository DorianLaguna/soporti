import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../models/ticket.dart';

/// Modelo de solicitud para crear un nuevo ticket.
class CreateTicketRequest {
  final String title;
  final String description;
  final String category;
  final String location;
  final String requesterId;

  const CreateTicketRequest({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.requesterId,
  });

  /// Convierte la solicitud a JSON para insertar en Supabase.
  /// El estatus se establece como 'Abierto' y la prioridad como 'Media' por defecto.
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'requester_id': requesterId,
        'status': 'Abierto',
        'priority': 'Media',
      };
}

/// Repositorio que abstrae las operaciones de tickets contra Supabase.
class TicketRepository {
  final SupabaseClient _client;

  TicketRepository(this._client);

  /// Obtiene los tickets de un solicitante ordenados por fecha de creación descendente.
  /// Lanza [NetworkException] si hay un error de conexión.
  /// Lanza [NotFoundException] si ocurre un error inesperado.
  Future<List<Ticket>> getTicketsByRequester(String userId) async {
    try {
      final response = await _client
          .from('tickets')
          .select()
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al obtener tickets: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }

  /// Obtiene un ticket específico por su ID.
  /// Lanza [NotFoundException] si el ticket no existe o no es accesible.
  /// Lanza [NetworkException] si hay un error de conexión.
  Future<Ticket> getTicketById(String ticketId) async {
    try {
      final response = await _client
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
  }

  /// Califica un ticket y lo cierra.
  /// Actualiza el rating y cambia el estatus a "Cerrado".
  /// Registra un evento de cierre con la calificación otorgada.
  /// Lanza [NotFoundException] si ocurre un error de base de datos.
  /// Lanza [NetworkException] si hay un error de conexión.
  Future<void> rateAndCloseTicket(String ticketId, int rating) async {
    try {
      // Actualizar el ticket: rating, estatus a Cerrado, updated_at
      await _client.from('tickets').update({
        'rating': rating,
        'status': 'Cerrado',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', ticketId);

      // Obtener el usuario actual para registrar quién realizó la acción
      final userId = _client.auth.currentUser!.id;

      // Registrar evento de cierre en ticket_events
      await _client.from('ticket_events').insert({
        'ticket_id': ticketId,
        'event_type': 'closed',
        'description': 'Ticket cerrado con calificación $rating/5',
        'is_internal': false,
        'created_by': userId,
      });
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al cerrar ticket: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }

  /// Crea un nuevo ticket y registra un evento inicial de tipo 'created'.
  /// Lanza [NetworkException] si hay un error de conexión.
  /// Lanza [NotFoundException] si ocurre un error al insertar.
  Future<Ticket> createTicket(CreateTicketRequest request) async {
    try {
      // Insertar el ticket en la tabla tickets.
      final ticketResponse = await _client
          .from('tickets')
          .insert(request.toJson())
          .select()
          .single();

      final ticket = Ticket.fromJson(ticketResponse);

      // Registrar evento inicial de creación en ticket_events.
      await _client.from('ticket_events').insert({
        'ticket_id': ticket.id,
        'event_type': 'created',
        'description': 'Ticket creado',
        'is_internal': false,
        'created_by': request.requesterId,
      });

      return ticket;
    } on PostgrestException catch (e) {
      throw NotFoundException('Error al crear ticket: ${e.message}');
    } catch (e) {
      throw const NetworkException();
    }
  }
}

/// Provider que expone el repositorio de tickets.
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TicketRepository(client);
});
