import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/ticket.dart';
import '../constants/app_colors.dart';
import 'priority_chip.dart';
import 'status_chip.dart';

/// Card que muestra un resumen de ticket en la lista.
///
/// Incluye:
/// - Borde izquierdo coloreado según prioridad (4px)
/// - Código SOP-XXXX (bold) a la izquierda superior
/// - Tiempo relativo (timeago en español) a la derecha superior
/// - Título truncado a 50 chars debajo
/// - Row con PriorityChip + StatusChip en la parte inferior
/// - Callback onTap para navegación al detalle
class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCard({super.key, required this.ticket, this.onTap});

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppColors.priorityColor(ticket.priority);

    // Configurar locale español para timeago (idempotente)
    timeago.setLocaleMessages('es', timeago.EsMessages());
    final relativeTime = timeago.format(ticket.createdAt, locale: 'es');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      // Fila superior: código + tiempo relativo
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
                            relativeTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Título truncado
                      Text(
                        ticket.truncatedTitle,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Fila inferior: chips de prioridad y estatus
                      Row(
                        children: [
                          PriorityChip(priority: ticket.priority),
                          const SizedBox(width: 8),
                          StatusChip(status: ticket.status),
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
