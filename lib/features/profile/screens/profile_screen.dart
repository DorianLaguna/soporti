import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/repositories/auth_repository.dart';
import '../providers/profile_provider.dart';

/// Pantalla de perfil del usuario.
/// Muestra información del usuario (nombre, correo, rol, ubicación)
/// y permite cerrar sesión.
///
/// Requirements: 14.1, 14.2
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                AppStrings.error,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text(AppStrings.error));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Avatar con iniciales
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.uvmGreen,
                  child: Text(
                    _getInitials(profile.fullName),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Nombre completo
                Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Correo corporativo
                Text(
                  profile.email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Información del perfil en tarjetas
                _ProfileInfoCard(
                  icon: Icons.badge_outlined,
                  label: 'Rol',
                  value: _formatRole(profile.role),
                ),
                const SizedBox(height: 12),
                _ProfileInfoCard(
                  icon: Icons.location_on_outlined,
                  label: AppStrings.locationLabel,
                  value: profile.location.isNotEmpty
                      ? profile.location
                      : 'No especificada',
                ),
                const SizedBox(height: 48),
                // Botón cerrar sesión
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _signOut(context, ref),
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: Text(
                      AppStrings.logout,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Obtiene las iniciales del nombre completo (máximo 2 letras).
  String _getInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Formatea el rol para mostrar con mayúscula y acentos correctos.
  String _formatRole(String role) {
    return switch (role) {
      'solicitante' => AppStrings.roleSolicitante,
      'tecnico' => AppStrings.roleTecnico,
      'supervisor' => AppStrings.roleSupervisor,
      _ => role,
    };
  }

  /// Cierra la sesión del usuario.
  /// GoRouter redirigirá automáticamente a /login al cambiar el auth state.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}

/// Widget interno que muestra una fila de información del perfil.
class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.uvmGreen, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
