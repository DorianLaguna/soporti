import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/profile.dart';
import '../providers/tech_provider.dart';

/// Modal de selección de técnico para reasignación de ticket.
///
/// Muestra un ModalBottomSheet con la lista de técnicos disponibles
/// (excluyendo al técnico actualmente asignado).
/// Retorna el [Profile] del técnico seleccionado o `null` si se cancela.
class ReassignModal extends ConsumerWidget {
  /// ID del técnico actualmente asignado (para excluirlo de la lista).
  final String? currentTechId;

  const ReassignModal({super.key, this.currentTechId});

  /// Muestra el modal y retorna el técnico seleccionado, o null si se cierra.
  static Future<Profile?> show(BuildContext context, {String? currentTechId}) {
    return showModalBottomSheet<Profile>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ReassignModal(currentTechId: currentTechId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techniciansAsync =
        ref.watch(availableTechniciansProvider(currentTechId));

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.selectTechnician,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: techniciansAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        AppStrings.error,
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(
                            availableTechniciansProvider(currentTechId)),
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
                data: (technicians) {
                  if (technicians.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No hay otros técnicos disponibles',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: technicians.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tech = technicians[index];
                      return _TechnicianTile(
                        technician: tech,
                        onTap: () => Navigator.of(context).pop(tech),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Tile individual para cada técnico en la lista.
class _TechnicianTile extends StatelessWidget {
  final Profile technician;
  final VoidCallback onTap;

  const _TechnicianTile({
    required this.technician,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.uvmGreen.withValues(alpha: 0.1),
        child: Text(
          _initials(technician.fullName),
          style: const TextStyle(
            color: AppColors.uvmGreen,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(
        technician.fullName,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        technician.email,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
    );
  }

  /// Extrae las iniciales (primeras letras de nombre y apellido).
  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
