import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide StorageException;

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../models/ticket_attachment.dart';

/// Tamaño máximo permitido para un archivo de imagen: 5 MB.
const int maxFileSizeBytes = 5 * 1024 * 1024;

/// Repositorio que gestiona la subida de imágenes a Supabase Storage
/// y el registro de adjuntos en la tabla ticket_attachments.
class StorageRepository {
  final SupabaseClient _client;

  StorageRepository(this._client);

  /// Sube una imagen asociada a un ticket a Supabase Storage.
  ///
  /// Valida que el archivo no exceda 5 MB antes de subir.
  /// Retorna la URL pública del archivo subido.
  ///
  /// Lanza [StorageException] si el archivo excede el tamaño máximo,
  /// si la subida falla, o si no se puede obtener la URL pública.
  Future<String> uploadImage(String ticketId, File file) async {
    // Validar tamaño del archivo.
    final fileSize = await file.length();
    if (fileSize > maxFileSizeBytes) {
      throw const StorageException(
        'La imagen excede el tamaño máximo permitido de 5 MB',
      );
    }

    // Generar nombre único para el archivo.
    final extension = file.path.split('.').last.toLowerCase();
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storagePath = 'tickets/$ticketId/$uniqueName';

    try {
      // Subir archivo a Supabase Storage.
      await _client.storage.from('ticket-attachments').upload(
            storagePath,
            file,
          );

      // Obtener la URL pública del archivo subido.
      final publicUrl = _client.storage
          .from('ticket-attachments')
          .getPublicUrl(storagePath);

      // Insertar registro en ticket_attachments.
      await _client.from('ticket_attachments').insert({
        'ticket_id': ticketId,
        'file_url': publicUrl,
      });

      return publicUrl;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(
        'Error al subir la imagen: ${e.toString()}',
      );
    }
  }

  /// Obtiene la lista de URLs de adjuntos asociados a un ticket.
  ///
  /// Retorna una lista de strings con las URLs públicas de los archivos.
  /// Lanza [StorageException] si ocurre un error al consultar.
  Future<List<String>> getTicketAttachments(String ticketId) async {
    try {
      final response = await _client
          .from('ticket_attachments')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((json) =>
              TicketAttachment.fromJson(json as Map<String, dynamic>).fileUrl)
          .toList();
    } catch (e) {
      throw StorageException(
        'Error al obtener adjuntos: ${e.toString()}',
      );
    }
  }
}

/// Provider que expone el repositorio de almacenamiento.
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageRepository(client);
});
