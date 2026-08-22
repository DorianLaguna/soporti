import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/ticket_event.dart';
import '../constants/app_colors.dart';

/// Widget que muestra un evento individual en la línea de tiempo.
///
/// Incluye:
/// - Punto de color a la izquierda (azul regular, verde para resolución)
/// - Línea vertical conectando eventos
/// - Fecha en formato "dd MMM · HH:mm"
/// - Descripción del evento debajo de la fecha
class TimelineEventWidget extends StatelessWidget {
  final TicketEvent event;
  final bool isLast;

  const TimelineEventWidget({
    super.key,
    required this.event,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isResolution = event.eventType == 'resolved';
    final dotColor = isResolution
        ? AppColors.timelineResolution
        : AppColors.timelineRegular;

    // Formato "dd MMM · HH:mm" en español
    final dateFormat = DateFormat("dd MMM · HH:mm", 'es');
    final formattedDate = dateFormat.format(event.createdAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna del indicador (punto + línea)
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 4),
                // Punto de color
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                // Línea vertical (no mostrar si es el último evento)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Contenido del evento
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fecha formateada
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Descripción del evento
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
