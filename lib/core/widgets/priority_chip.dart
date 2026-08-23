import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Chip coloreado que muestra la prioridad de un ticket.
/// El color de fondo corresponde a la prioridad (Crítica: rojo, Alta: naranja,
/// Media: ámbar, Baja: verde). El texto se ajusta (claro/oscuro) según el
/// contraste con el fondo.
class PriorityChip extends StatelessWidget {
  final String priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.priorityColor(priority);

    return Chip(
      label: Text(
        priority,
        style: TextStyle(
          color: AppColors.onColor(color),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}
