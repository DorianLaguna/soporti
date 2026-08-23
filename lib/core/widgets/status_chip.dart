import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Chip coloreado que muestra el estatus de un ticket.
/// El color de fondo corresponde al estatus (Abierto: azul medio, Asignado:
/// azul profundo, En proceso: naranja, En espera: gris, Resuelto: verde,
/// Cerrado: gris oscuro). El texto se ajusta (claro/oscuro) según el
/// contraste con el fondo.
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);

    return Chip(
      label: Text(
        status,
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
