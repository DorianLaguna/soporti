import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// Tipo de badge offline que indica el tipo de operación pendiente.
enum OfflineBadgeType {
  /// Ticket creado offline, pendiente de enviar al servidor.
  pendingSend,

  /// Estatus del ticket fue cambiado a resuelto offline.
  localResolved,

  /// Comentario creado offline, pendiente de sincronizar.
  unsyncedComment,
}

/// Badge descriptivo que se muestra sobre un ticket cuando el dispositivo
/// está sin conexión.
///
/// Los tipos de badge son:
/// - "Pendiente de enviar" — ticket creado offline
/// - "Estatus: resuelto local" — resolución marcada offline
/// - "Comentario sin sincronizar" — nota agregada offline
///
/// Este widget es exclusivamente visual. No hay lógica real de sincronización.
class OfflineTicketBadge extends StatelessWidget {
  final OfflineBadgeType type;

  const OfflineTicketBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (type) {
      OfflineBadgeType.pendingSend => (
          AppStrings.pendingSend,
          Icons.cloud_upload_outlined,
        ),
      OfflineBadgeType.localResolved => (
          AppStrings.localResolved,
          Icons.check_circle_outline,
        ),
      OfflineBadgeType.unsyncedComment => (
          AppStrings.unsyncedComment,
          Icons.comment_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.offlineBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.offlineBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.offlineText),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.offlineText,
            ),
          ),
        ],
      ),
    );
  }
}
